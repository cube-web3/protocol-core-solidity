// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import { Structs } from "../common/Structs.sol";
import { RouterStorage } from "./RouterStorage.sol";
import { ICube3Module } from "../interfaces/ICube3Module.sol";
import { ICube3Registry } from "../interfaces/ICube3Registry.sol";

import { ProtocolErrors } from "../libs/ProtocolErrors.sol";
import { IntegrationManagement } from "./IntegrationManagement.sol";

/// @dev This contract contains all the logic for managing the protocol
abstract contract ProtocolManagement is AccessControlUpgradeable, RouterStorage {
    /*//////////////////////////////////////////////////////////////
            PROTOCOL ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    // TODO: add convenience function for pausing/unpausing

    /// @dev We allow the registry to be set to the zero address in the event of a compromise. Removing the
    /// registry will prevent any new integrations from being registered.
    function setProtocolConfig(address registry, bool isPaused) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        // Checks: the registry, if provided, supports the ICube3Registry interface.
        if (registry != address(0)) {
            if (!ERC165Checker.supportsInterface(registry, type(ICube3Registry).interfaceId)) {
                revert ProtocolErrors.Cube3Router_NotValidRegistryInterface();
            }
        }

        // Effects: sets the registry and updates the paused state.
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
        // Retrieve the module address using the ID.
        address module = getModuleAddressById(moduleId);

        // Checks: The module exists.
        if (module == address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleNotInstalled(moduleId);
        }

        // TODO: check this
        (bool success, bytes memory returnOrRevertData) = payable(module).call(fnCalldata);
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
        // Checks: the module address is valid.
        if (moduleAddress == address(0)) {
            revert ProtocolErrors.Cube3Router_InvalidAddressForModule();
        }
        // Checks: the module ID is valid.
        if (moduleId == bytes16(0)) {
            revert ProtocolErrors.Cube3Router_InvalidIdForModule();
        }

        // TODO: should be module base
        // Checks: the deployed module supports the ICube3Module interface.
        if (!ERC165Checker.supportsInterface(moduleAddress, type(ICube3Module).interfaceId)) {
            revert ProtocolErrors.Cube3Router_ModuleInterfaceNotSupported();
        }

        // Checks: the module being installed insn't a duplicate.
        if (getModuleAddressById(moduleId) != address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleAlreadyInstalled();
        }

        // The module version is used as the salt for the module ID, so we need to ensure that
        // it matches the desired module being installed
        string memory moduleVersion = ICube3Module(moduleAddress).moduleVersion();

        // Checks: the module version matches the module ID generated from the hash.
        if (bytes16(keccak256(abi.encode(moduleVersion))) != moduleId) {
            revert ProtocolErrors.Cube3Router_ModuleVersionNotMatchingID();
        }

        // Checks: the module hasn't been deprecated. Prevents reinstallation of a deprecated version.
        if (ICube3Module(moduleAddress).isDeprecated() || getIsModuleVersionDeprecated(moduleId)) {
            revert ProtocolErrors.Cube3Router_CannotInstallDeprecatedModule();
        }

        // Effects: install the module.
        _setModuleInstalled(moduleId, moduleAddress, moduleVersion);
    }

    function deprecateModule(bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        // Retrieve the module address using the ID.
        address moduleToDeprecate = getModuleAddressById(moduleId);

        // Checks: the module is installed.
        if (moduleToDeprecate == address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleNotInstalled(moduleId);
        }

        // Interactions: call into the module to deprecate it.
        try ICube3Module(moduleToDeprecate).deprecate() returns (string memory version) {
            // TODO: should add to deprecateedMapping?
            _setModuleVersionDeprecated(moduleId, version);
            _deleteInstalledModule(moduleId);
        } catch {
            revert ProtocolErrors.Cube3Router_ModuleDeprecationFailed();
        }
    }
}
