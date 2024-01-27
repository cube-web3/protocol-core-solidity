// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC165CheckerUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import { Structs } from "../common/Structs.sol";
import { RouterStorage } from "./RouterStorage.sol";
import { ICube3Module } from "../interfaces/ICube3Module.sol";
import { ICube3Registry } from "../interfaces/ICube3Registry.sol";

import { IntegrationManagement } from "./IntegrationManagement.sol";

/// @dev This contract contains all the logic for managing the protocol
abstract contract ProtocolManagement is AccessControlUpgradeable, RouterStorage {
    /*//////////////////////////////////////////////////////////////
            PROTOCOL ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    // TODO: add convenience function for pausing/unpausing

    /// @dev We allow the registry to be set to the zero address in the event of a compromise
    function setProtocolConfig(address registry, bool isPaused) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        if (registry != address(0)) {
            require(
                ERC165CheckerUpgradeable.supportsInterface(registry, type(ICube3Registry).interfaceId),
                "CR22: interface not supported"
            );
        }
        _setProtocolConfig(registry, isPaused);
    }

    /// @dev used to call privileged functions on modules where only the router has access
    /// @dev never know if it needs to be payable or not
    function callModuleFunctionAsAdmin(
        bytes16 moduleId,
        bytes calldata fnCalldata
    )
        external
        payable
        onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE)
        returns (bytes memory)
    {
        address module = getModuleAddressById(moduleId);
        require(module != address(0), "CR03: non-existent module");

        (bool success, bytes memory returnOrRevertData) = payable(module).call(fnCalldata);
        // TODO: check this
        if (!success) {
            // Bubble up the revert data unmolested.
            assembly {
                revert(
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    add(returnOrRevertData, 0x20),
                    // Length of revert data.
                    mload(returnOrRevertData)
                )
            }
        }
        return returnOrRevertData;
    }

    /*//////////////////////////////////////////////////////////////
            MODULE ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function installModule(address moduleAddress, bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        require(moduleAddress != address(0), "CR14: invalid module");
        require(moduleId != bytes16(0), "CR15: invalid id");
        require(
            ERC165CheckerUpgradeable.supportsInterface(moduleAddress, type(ICube3Module).interfaceId),
            "CR18: interface not supported"
        );

        require(getModuleAddressById(moduleId) == address(0), "CR07: module version exists");

        // The module version is used as the salt for the module ID, so we need to ensure that
        // it matches the desired module being installed
        string memory moduleVersion = ICube3Module(moduleAddress).moduleVersion();
        require(bytes16(keccak256(abi.encode(moduleVersion))) == moduleId, "CR08: module not deployed");

        // check that the module hasn't been deprecated to prevent reinstallation
        require(!ICube3Module(moduleAddress).isDeprecated(), "CR16: module deprecated");

        _setModuleInstalled(moduleId, moduleAddress, moduleVersion);
    }

    function deprecateModule(bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        address moduleToDeprecate = getModuleAddressById(moduleId);
        require(moduleToDeprecate != address(0), "CR09: non-existent version");
        (bool success, string memory version) = ICube3Module(moduleToDeprecate).deprecate();
        require(success, "CR17: deprecation unsuccessful");
        _deleteInstalledModule(moduleId, moduleToDeprecate, version);
    }
}
