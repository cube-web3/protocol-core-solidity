// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ICube3SecurityModule} from "@src/interfaces/ICube3SecurityModule.sol";
import {ICube3Registry} from "@src/interfaces/ICube3Registry.sol";

import {IProtocolManagement} from "@src/interfaces/IProtocolManagement.sol";

import {IntegrationManagement} from "@src/abstracts/IntegrationManagement.sol";
import {RouterStorage} from "@src/abstracts/RouterStorage.sol";
import {Structs} from "@src/common/Structs.sol";
import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";

/// @title ProtocolManagement
/// @notice This contract contains all the logic for managing the protocol.
/// @dev This contract's functions can only be accessed by CUBE3 accounts with privileged roles.
abstract contract ProtocolManagement is IProtocolManagement, AccessControlUpgradeable, RouterStorage {
    /*//////////////////////////////////////////////////////////////
            PROTOCOL ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProtocolManagement
    function setPausedUnpaused(bool isPaused) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        // Effects: sets the registry and updates the paused state.
        _setProtocolPausedUnpaused(isPaused);
    }

    /// @inheritdoc IProtocolManagement
    function updateProtocolConfig(address registry, bool isPaused) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        // Checks: the registry, if provided, supports the ICube3Registry interface.
        if (registry != address(0)) {
            if (!ERC165Checker.supportsInterface(registry, type(ICube3Registry).interfaceId)) {
                revert ProtocolErrors.Cube3Router_NotValidRegistryInterface();
            }
        }

        // Effects: sets the registry and updates the paused state.
        _updateProtocolConfig(registry, isPaused);
    }

    /// @inheritdoc IProtocolManagement
    function callModuleFunctionAsAdmin(
        bytes16 moduleId,
        bytes calldata fnCalldata
    ) external payable onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) returns (bytes memory) {
        // Retrieve the module address using the ID.
        address module = getModuleAddressById(moduleId);

        // Checks: The module exists.
        if (module == address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleNotInstalled(moduleId);
        }

        (bool success, bytes memory returnOrRevertData) = payable(module).call{value: msg.value}(fnCalldata);
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

    /// @inheritdoc IProtocolManagement
    function installModule(address moduleAddress, bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        // Checks: the module ID is valid.
        if (moduleId == bytes16(0)) {
            revert ProtocolErrors.Cube3Router_InvalidIdForModule();
        }

        // Checks: the deployed module supports the ICube3SecurityModule interface. Will revert if the module
        // address is the zero address.
        if (!ERC165Checker.supportsInterface(moduleAddress, type(ICube3SecurityModule).interfaceId)) {
            revert ProtocolErrors.Cube3Router_ModuleInterfaceNotSupported();
        }

        // Checks: the module being installed insn't a duplicate.
        if (getModuleAddressById(moduleId) != address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleAlreadyInstalled();
        }

        // The module version is used as the salt for the module ID, so we need to ensure that
        // it matches the desired module being installed
        string memory moduleVersion = ICube3SecurityModule(moduleAddress).moduleVersion();

        // Checks: the module version matches the module ID generated from the hash.
        if (bytes16(keccak256(abi.encode(moduleVersion))) != moduleId) {
            revert ProtocolErrors.Cube3Router_ModuleVersionNotMatchingID();
        }

        // Checks: the module hasn't been deprecated. Prevents reinstallation of a deprecated version.
        if (ICube3SecurityModule(moduleAddress).isDeprecated() || getIsModuleVersionDeprecated(moduleId)) {
            revert ProtocolErrors.Cube3Router_CannotInstallDeprecatedModule();
        }

        // Effects: install the module.
        _setModuleInstalled(moduleId, moduleAddress, moduleVersion);
    }

    /// @inheritdoc IProtocolManagement
    function deprecateModule(bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE) {
        // Retrieve the module address using the ID.
        address moduleToDeprecate = getModuleAddressById(moduleId);

        // Checks: the module is installed.
        if (moduleToDeprecate == address(0)) {
            revert ProtocolErrors.Cube3Router_ModuleNotInstalled(moduleId);
        }

        // Interactions: call into the module to deprecate it.
        try ICube3SecurityModule(moduleToDeprecate).deprecate() returns (string memory version) {
            _setModuleVersionDeprecated(moduleId, version);
            _deleteInstalledModule(moduleId);
        } catch {
            revert ProtocolErrors.Cube3Router_ModuleDeprecationFailed();
        }
    }
}
