// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { ICube3Router } from "../interfaces/ICube3Router.sol";
import { ICube3Module } from "../interfaces/ICube3Module.sol";
import { ModuleBaseEvents } from "./ModuleBaseEvents.sol";
import { ProtocolErrors } from "../libs/ProtocolErrors.sol";
import { ProtocolConstants } from "../common/ProtocolConstants.sol";

/// @dev See {ICube3Module}
abstract contract ModuleBase is ICube3Module, ModuleBaseEvents, ERC165, ProtocolConstants {
    // interface wrapping the CUBE3 Router proxy contract for convenience.
    ICube3Router internal immutable cube3router;

    /// @inheritdoc	ICube3Module
    string public moduleVersion;
    bytes16 public immutable moduleId;

    // TODO: is this needed?
    // The expected CUBE3 Payload length (in bytes) for this module.
    uint256 public immutable expectedPayloadSize;

    /// @inheritdoc	ICube3Module
    bool public isDeprecated;

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev During construction, the module makes a call to the router to ensure the version supplied has
    /// not already been installed.
    /// @dev The `version` string should be validated for correctness prior to deployment.
    /// @param cubeRouterProxy Contract address of the Cube3RouterImpl proxy.
    /// @param version Human-readable module version, where minimum valid length is 9 bytes and max valid length is 32
    /// bytes: `xxx-x.x.x`
    constructor(address cubeRouterProxy, string memory version, uint256 payloadSize) {
        // Checks: The address provided for the Router proxy is not null.
        if (cubeRouterProxy == address(0)) {
            revert ProtocolErrors.Cube3Module_InvalidRouter();
        }

        // Checks: The version string conforms to the schema: {xxx-x.x.x}
        if (!_isValidVersionSchema(version)) {
            revert ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema();
        }

        // TODO: probably remove this
        require(payloadSize > 0, "TODO: invalid payload size");

        // Assign the module version.
        moduleVersion = version;

        // Use the 128 most significant bits of the keccak256 hash of the version string. This
        // allows for efficient packing of the routing information. Modules are purpose-built
        // smart contracts containing unique functionality, so it's not feasible to produce enough
        // modules to ever cause a collision despite using bytes16.
        moduleId = bytes16(keccak256(abi.encode(moduleVersion)));

        expectedPayloadSize = payloadSize;

        cube3router = ICube3Router(cubeRouterProxy);

        // Checks: for an existing version so we don't deploy two modules with the same version
        if (cube3router.getModuleAddressById(moduleId) != address(0)) {
            revert ProtocolErrors.Cube3Module_ModuleVersionExists();
        }

        // Logs: the deployment details of the module.
        emit ModuleDeployed(cubeRouterProxy, moduleId, version);
    }

    /*//////////////////////////////////////////////////////////////
            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Restricts function calls to the address of the Router Proxy
    modifier onlyCube3Router() {
        if (msg.sender != address(cube3router)) {
            revert ProtocolErrors.Cube3Module_OnlyRouterAsCaller();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
            DEPRECATION
    //////////////////////////////////////////////////////////////*/

    // TODO: test custom override here and call super.deprecate();
    /// @inheritdoc	ICube3Module
    /// @dev Can be overridden in the event additional logic needs to be executed during deprecation.
    /// @dev Overriden function MUST use `onlyCube3Router` modifier.
    function deprecate() external virtual onlyCube3Router returns (string memory) {
        isDeprecated = true;
        string memory version = moduleVersion; // gas-saving
        emit ModuleDeprecated(moduleId, version);
        return version;
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICube3Module).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
            VERSION UTILS
    //////////////////////////////////////////////////////////////*/

    /// @dev Module installation is infrequent and performed by CUBE3, so the slightly elevated gas cost
    ///      of this check is acceptable given the operational significance.
    /// @dev Is NOT a comprehensive validation. Validation on the schema should be done in the deployment script.
    /// @dev A minimal check evaluating that the version string conforms to the schema: {xxx-x.x.x}
    /// @dev Checks for the correct version schema by counting the "." separating MAJOR.MINOR.PATCH
    /// @dev Checks for the presence of the single "-" separating name and version number
    /// @dev Known exception is omitting semver numbers, eg {xxxxxx-x.x.} or {xxxxx-x..x}
    function _isValidVersionSchema(string memory version_) internal pure returns (bool) {
        // check the length of the version string does not exceed 32 bytes.
        if (bytes(version_).length < 9 || bytes(version_).length > 32) {
            return false;
        }

        uint256 versionSeparatorCount;
        uint256 dashCount;

        bytes memory b = bytes(version_);
        uint256 len = b.length;

        for (uint256 i; i < len;) {
            bytes1 char = b[i];
            if (char == ".") {
                versionSeparatorCount++;
            } else if (char == "-") {
                dashCount++;
            }
            unchecked {
                ++i;
            }
        }
        if (versionSeparatorCount != 2 || dashCount != 1) {
            return false;
        }
        return true;
    }
}
