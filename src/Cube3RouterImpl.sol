// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import {
    AccessControlUpgradeable,
    ERC165Upgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { ICube3RouterImpl } from "@src/interfaces/ICube3RouterImpl.sol";
import { ICube3Registry } from "@src/interfaces/ICube3Registry.sol";
import { ProtocolManagement } from "@src/abstracts/ProtocolManagement.sol";
import { IntegrationManagement } from "@src/abstracts/IntegrationManagement.sol";
import { RouterStorage } from "@src/abstracts/RouterStorage.sol";
import { RoutingUtils } from "@src/libs/RoutingUtils.sol";
import { SignatureUtils } from "@src/libs/SignatureUtils.sol";
import { AddressUtils } from "@src/libs/AddressUtils.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { Structs } from "@src/common/Structs.sol";
import { ProtocolConstants } from "@src/common/ProtocolConstants.sol";

/// @title Cube3RouterImpl
/// @notice Defines the implementation contract for the upgradeable CUBE3 Router.
/// @dev See {ICube3RouterImpl} for documentation, which is inherited implicitly via
/// {ProtocolManagement} and {IntegrationManagement}.
/// Notes:
/// - All storage variables are defined in {RouterStorage} and accessed via
/// dedicated getter and setter functions.
contract Cube3RouterImpl is
    ICube3RouterImpl,
    ContextUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ProtocolManagement,
    IntegrationManagement
{
    using AddressUtils for address;
    using RoutingUtils for bytes;
    using SignatureUtils for bytes32;

    /// @dev Checks the call can only take place in another contract's constructor.
    modifier onlyConstructor() {
        address(this).assertIsEOAorConstructorCall();
        _;
    }

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Lock the implementation contract at deployment to prevent it being used until
    /// it is initialized.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
            PROXY + UPGRADE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3RouterImpl
    function initialize(address registry) public initializer onlyConstructor {
        // Checks: registry is not the zero address
        if (registry == address(0)) {
            revert ProtocolErrors.Cube3Router_InvalidRegistry();
        }
        // Checks: the registry is a valid contract.
        registry.assertIsContract();

        __AccessControl_init();
        __UUPSUpgradeable_init();
        __ERC165_init();

        // Not paused by default.
        _updateProtocolConfig(registry, false);

        // The deployer is the EOA who initiated the transaction, and is the account that will revoke
        // it's own access permissions and add new ones immediately following deployment. Using tx.origin accounts
        // for salted contract creation via another contract.
        _grantRole(DEFAULT_ADMIN_ROLE, tx.origin);
    }

    /// @dev Adds access control logic to the {upgradeTo} function
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) { }

    /// @inheritdoc ICube3RouterImpl
    function getImplementation() external view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    /*//////////////////////////////////////////////////////////////
            ROUTING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3RouterImpl
    function routeToModule(
        address integrationMsgSender,
        uint256 integrationMsgValue,
        bytes calldata integrationCalldata
    )
        external
        returns (bytes32)
    {
        // Extract the originating call's function selector from its calldata so that we can check if it's protected.
        bytes4 integrationFnCallSelector = integrationCalldata.parseIntegrationFunctionCallSelector();

        // Checks: if the function is protected, if the integration's registration status is REVOKED, or if the protocol
        // is paused.
        if (_shouldBypassRouting(integrationFnCallSelector)) {
            return PROCEED_WITH_CALL;
        }

        // Extracts the module payload data, which comprises: moduleFnSelector | moduleId | modulePayload.
        // The orginating function's calldata is hashed, without the modulePayload, to create a digest that validates
        // none of the call's arguments differ from those used to generate the signature contained in the payload, if
        // required.
        (bytes4 moduleFnSelector, bytes16 moduleId, bytes memory modulePayload, bytes32 integrationCalldataDigest) =
            integrationCalldata.parseRoutingInfoAndPayload();

        // Checks: The module ID is mapped to an installed module.  Including the module address in the payload
        // as opposed to the module ID that needs to be retrieved from storage, could lead to spoofing.
        address module = getModuleAddressById(moduleId);
        if (module == address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleNotInstalled(moduleId);
        }

        // create the calldata for the module call
        bytes memory moduleCalldata = abi.encodeWithSelector(
            moduleFnSelector,
            Structs.TopLevelCallComponents(
                integrationMsgSender,
                msg.sender, // this will be the proxy address if the integration uses a proxy
                integrationMsgValue,
                integrationCalldataDigest // the top-level function call's msg.data without the cube3SecurePayload
            ),
            modulePayload
        );

        // Interactions: route the call to the module using the data extracted from the integration's calldata.
        return _executeModuleFunctionCall(module, moduleCalldata);
    }

    /*//////////////////////////////////////////////////////////////
            ROUTING HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Determines whether to forward the relative parts of the calldata to the Security Module.
    /// @param integrationFnCallSelector The function selector of the top-level call to the integration.
    /// @dev There's no need to check for a registration status of PENDING, as an integration's function
    /// protection status cannot be enabled until it's registered, and thus the first condition will always
    /// be false and thus routing should be bypassed.
    /// @return Whether routing to the module should be bypassed: `true` to bypass the module and return early
    /// to the integration, and 'false` to continue on and utilize the Security Module.
    function _shouldBypassRouting(bytes4 integrationFnCallSelector) internal view returns (bool) {
        // Checks: Whether the function is protected. Checking this first ensures that there's only one SLOAD
        // for an integration that has protection disabled before returning.
        // note: It's more gas-efficient to use 3 separate conditionals versus chaining with logical ||.
        if (!getIsIntegrationFunctionProtected(msg.sender, integrationFnCallSelector)) {
            return true;
        }

        // Checks: Whether the integration has had its status REVOKED.
        if (getIntegrationStatus(msg.sender) == Structs.RegistrationStatusEnum.REVOKED) {
            return true;
        }

        // Checks: Whether the protocol is paused.
        // note: warms the slot that contains the registry address which is retrieved later on in the call.
        if (getIsProtocolPaused()) {
            return true;
        }

        return false;
    }

    /// @notice Performs the call to the Security Module.
    /// @dev Reverts under any condition other than a successful return.
    function _executeModuleFunctionCall(address module, bytes memory moduleCalldata) internal returns (bytes32) {
        // Interactions: Makes the call to the desired module, calldataa includes the relevant information about the
        // originating function call.
        (bool success, bytes memory returnOrRevertData) = module.call(moduleCalldata);
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

        // Interactions: A CUBE3 module will always return the bytes32 value for keccak256("MODULE_CALL_SUCCEEDED").
        // This statement operates like an assertion, whereby any result other than success will result in a revert.
        if (returnOrRevertData.length == 32) {
            // Successful and returned a decodable boolean.
            if (abi.decode(returnOrRevertData, (bytes32)) == MODULE_CALL_SUCCEEDED) {
                return PROCEED_WITH_CALL;
            } else {
                revert ProtocolErrors.Cube3Router_ModuleReturnedInvalidData();
            }
        } else {
            revert ProtocolErrors.Cube3Router_ModuleReturnDataInvalidLength(returnOrRevertData.length);
        }
    }
    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3RouterImpl
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ICube3RouterImpl)
        returns (bool)
    {
        return interfaceId == type(ICube3RouterImpl).interfaceId || super.supportsInterface(interfaceId);
    }
}
