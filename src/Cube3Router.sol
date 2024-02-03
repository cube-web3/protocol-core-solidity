// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    AccessControlUpgradeable,
    ERC165Upgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC165CheckerUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { ICube3Router } from "./interfaces/ICube3Router.sol";
import { ICube3Registry } from "./interfaces/ICube3Registry.sol";

import { ProtocolManagement } from "./abstracts/ProtocolManagement.sol";
import { IntegrationManagement } from "./abstracts/IntegrationManagement.sol";
import { PayloadUtils } from "./libs/PayloadUtils.sol";
import { SignatureUtils } from "./libs/SignatureUtils.sol";

import { AddressUtils } from "./libs/AddressUtils.sol";
import { Structs } from "./common/Structs.sol";
import { ProtocolConstants } from "./common/ProtocolConstants.sol";
import { RouterStorage } from "./abstracts/RouterStorage.sol";

/// @dev See {ICube3Router}
/// @dev All storage variables are defined in RouterStorage.sol and accessed via dedicated getter and setter functions

contract Cube3Router is
    ContextUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ProtocolManagement,
    IntegrationManagement,
    ProtocolConstants
{
    using AddressUtils for address;
    using PayloadUtils for bytes;
    using SignatureUtils for bytes32;

    /// @dev The implementation should only be initialized in the constructor of the proxy
    modifier onlyConstructor() {
        require(address(this).code.length == 0, "CR02: not in constructor");
        _;
    }

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev    lock the implementation contract at deployment to prevent it being used
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
            PROXY + UPGRADE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Initialization can only take place once, and is called by the proxy's constructor.
    function initialize(address registry) public initializer onlyConstructor {
        require(registry != address(0), "Registry ZeroAddress");

        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC165_init();

        // Not paused by default.
        _setProtocolConfig(registry, false);

        // The deployer is the EOA who initiated the transaction, and is the account that will revoke
        // it's own access permissions and add new ones immediately following deployment. Using tx.origin accounts
        // for salted contract creation via another contract.
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
    }

    /// @dev Adds access control logic to the {upgradeTo} function
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) { }

    /// @dev returns the proxy's current implementation address
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /*//////////////////////////////////////////////////////////////
            ROUTING
    //////////////////////////////////////////////////////////////*/

    /// @dev Routes the module payload contained in the integrationCalldata to the appropriate module, provided
    ///      the originating function call's function is protected.
    /// @dev Will return PROCEED_WITH_CALL if the function is not protected, the integration's registration status is
    /// REVOKED,
    ///      or the protocol is paused.
    function routeToModule(
        address integrationMsgSender,
        uint256 integrationMsgValue,
        bytes calldata integrationCalldata
    )
        external
        returns (bytes32)
    {
        // Extract the originating call's function selector from its calldata so that we can check if it's protected.
        bytes4 integrationFnCallSelector = integrationCalldata.extractCalledIntegrationFunctionSelector();

        // Checks: Whether the function is protected. Checing this first ensures that there's only one SLOAD
        // for an integration that has protection disabled before returning.
        // note: It's cheaper gas-wise to use 3 separate conditionals versus chaining with logical ||.
        if (!getIsIntegrationFunctionProtected(msg.sender, integrationFnCallSelector)) {
            return PROCEED_WITH_CALL;
        }

        // Checks: Whether the integration has had its status REVOKED.
        if (getIntegrationStatus(msg.sender) == Structs.RegistrationStatusEnum.REVOKED) {
            return PROCEED_WITH_CALL;
        }

        // Checks: Whether the protocol is paused.
        // note: warms the slot that contains the registry address which is retrieved further on.
        if (getIsProtocolPaused()) {
            return PROCEED_WITH_CALL;
        }

        // Extracts the payload data, which comprises: moduleFnSelector | moduleId | modulePayload | moduleLength.  The
        // orginating
        // function's calldata is hashed, without the modulePayload, to create a digest that validates none of the
        // call's arguments
        // differ from those used to generate the signature contained in the payload, if required.
        (bytes4 moduleFnSelector, bytes16 moduleId, bytes memory modulePayload, bytes32 integrationCalldataDigest) =
            integrationCalldata.extractPayloadDataFromCalldata();

        // Checks: The module ID is mapped to an installed module.  Including the module address, instead of the ID,
        // could lead to spoofing.
        address module = getModuleAddressById(moduleId);
        require(module != address(0), "CR03: non-existent module");

        // create the calldata for the module call
        bytes memory moduleCalldata = abi.encodeWithSelector(
            moduleFnSelector,
            Structs.IntegrationCallMetadata(
                integrationMsgSender,
                msg.sender, // this will be the proxy address if the integration uses a proxy
                integrationMsgValue,
                integrationCalldataDigest // the originating function call's msg.data without the cube3SecurePayload //
                    // TODO: better name
            ),
            modulePayload
        );

        // Interactions: Makes the call to the desired module, including the relevant information about the originating
        // function call.
        (bool success, bytes memory returnOrRevertData) = module.call(moduleCalldata);
        // TODO: does this bubble up if it's not in a try/catch
        if (!success) {
            // Bubble up the revert data from the module call.
            assembly {
                revert(
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    add(returnOrRevertData, 0x20),
                    // Length of revert data.
                    mload(returnOrRevertData)
                )
            }
        }

        // Interactions: A CUBE3 module will always return the bytes32 equivalent of keccak256("MODULE_CALL_SUCCEEDED").
        // This operates like an assertion, whereby any result other than success will result in a revert.
        if (returnOrRevertData.length == 32) {
            // Successful and returned a decodable boolean.
            if (abi.decode(returnOrRevertData, (bytes32)) == MODULE_CALL_SUCCEEDED) {
                return PROCEED_WITH_CALL;
            } else {
                revert("tODO: Module failed");
            }
        } else {
            revert("CR04: invalid module response");
        }
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ICube3Router).interfaceId || super.supportsInterface(interfaceId);
    }
}
