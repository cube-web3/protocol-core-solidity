// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import {IRouterStorage} from "@src/interfaces/IRouterStorage.sol";
import { Structs } from "@src/common/Structs.sol";
import { ProtocolEvents } from "@src/common/ProtocolEvents.sol";
import { ProtocolAdminRoles } from "@src/common/ProtocolAdminRoles.sol";
import { ProtocolConstants } from "@src/common/ProtocolConstants.sol";

struct Cube3State {
    Structs.ProtocolConfig protocolConfig;
    /*//////////////////////////////////////////////////////////////
        MODULE STORAGE
    //////////////////////////////////////////////////////////////*/

    // stores module IDs mapped to their corresponding module contract addresses
    mapping(bytes16 moduleId => address module) idToModules;
    /*//////////////////////////////////////////////////////////////
        INTEGRATION MANAGER STORAGE
    //////////////////////////////////////////////////////////////*/

    // mapping of integration_address => pending_admin_address, used as part of a two step
    // transfer of admin privileges for an integration
    mapping(address integration => address pendingAdmin) integrationToPendingAdmin;
    // mapping of integration_address => integration_state, where an integration's state stores
    // its admin address and registration status
    mapping(address integration => Structs.IntegrationState state) integrationToState;
    // mapping of integration_address => (mapping of function_selector => protection_status)
    mapping(address integration => mapping(bytes4 selector => bool isProtected)) integrationToFunctionProtectionStatus;
    // store a hash of the used registrar signature to prevent re-registration in the event of a revocation
    // replaces the need for an onchain blacklist, as the CUBE3 service will not issue a registarSignature to a revoked
    // integration
    mapping(bytes32 signature => bool used) usedRegistrarSignatureHashes;
    mapping(bytes16 moduleId => bool deprecated) deprecatedModules;
}

/// @title RouterStorage
/// @notice The contracts contains all logic for reading and writing to contract storage.
/// @dev This contract utilizes namespaced storage layout (ERC-7201). All storage access happens via
///      the `_state()` function, which returns a storage pointer to the `Cube3State` struct.  Storage variables
///      can only be accessed via dedicated getter and setter functions.
abstract contract RouterStorage is IRouterStorage, ProtocolEvents, ProtocolAdminRoles, ProtocolConstants {
    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    // keccak256(abi.encode(uint256(keccak256("cube3.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant CUBE3_ROUTER_STORAGE_LOCATION =
        0xd26911dcaedb68473d1e75486a92f0a8e6ef3479c0c1c4d6684d3e2888b6b600;

    /// @custom:storage-location cube3.storage
    function _state() private pure returns (Cube3State storage state) {
        assembly {
            state.slot := CUBE3_ROUTER_STORAGE_LOCATION
        }
    }

    /*//////////////////////////////////////////////////////////////
        GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRouterStorage
    function getIsIntegrationFunctionProtected(address integration, bytes4 fnSelector) public view returns (bool) {
        return _state().integrationToFunctionProtectionStatus[integration][fnSelector];
    }

    /// @inheritdoc IRouterStorage
    function getIntegrationStatus(address integration) public view returns (Structs.RegistrationStatusEnum) {
        return _state().integrationToState[integration].registrationStatus;
    }

    /// @inheritdoc IRouterStorage
    function getIntegrationPendingAdmin(address integration) public view returns (address) {
        return _state().integrationToPendingAdmin[integration];
    }

    /// @inheritdoc IRouterStorage
    function getIntegrationAdmin(address integration) public view returns (address) {
        return _state().integrationToState[integration].admin;
    }

    /// @inheritdoc IRouterStorage
    function getIsProtocolPaused() public view returns (bool) {
        return _state().protocolConfig.paused;
    }

    /// @inheritdoc IRouterStorage
    function getModuleAddressById(bytes16 moduleId) public view returns (address) {
        return _state().idToModules[moduleId];
    }

    /// @inheritdoc IRouterStorage
    function getRegistrarSignatureHashExists(bytes32 signatureHash) public view returns (bool) {
        return _state().usedRegistrarSignatureHashes[signatureHash];
    }

    /// @inheritdoc IRouterStorage
    function getProtocolConfig() external view returns (Structs.ProtocolConfig memory) {
        return _state().protocolConfig;
    }

    /// @inheritdoc IRouterStorage
    function getRegistryAddress() public view returns (address) {
        return _state().protocolConfig.registry;
    }

    /// @inheritdoc IRouterStorage
    function getIsModuleVersionDeprecated(bytes16 moduleId) public view returns (bool) {
        return _state().deprecatedModules[moduleId];
    }

    /*//////////////////////////////////////////////////////////////
        SETTERS
    //////////////////////////////////////////////////////////////*/

    // TODO: separe into two functions.
    /// @notice Updates the protocol configuration in storage with the new registry and paused state.
    /// @dev If the `registry` is not being changed, the existing address should be passed.
    /// @param registry The new registry address.
    /// @param isPaused The new paused state.
    function _updateProtocolConfig(address registry, bool isPaused) internal {
        _state().protocolConfig = Structs.ProtocolConfig(registry, isPaused);
        emit ProtocolConfigUpdated(registry, isPaused);
        if (registry == address(0)) {
            emit ProtocolRegistryRemoved();
        }
    }

    // TODO: remove the currentadmin and read from storage
    /// @notice Sets the pending admin for an integration in storage.
    /// @dev `currentAdmin` should always be `msg.sender`.
    /// @param integration The integration address to set the pending admin for.
    /// @param currentAdmin The current admin of the integration.
    /// @param pendingAdmin The new pending admin of the integration.
    function _setPendingIntegrationAdmin(address integration, address currentAdmin, address pendingAdmin) internal {
        _state().integrationToPendingAdmin[integration] = pendingAdmin;
        emit IntegrationAdminTransferStarted(integration, currentAdmin, pendingAdmin);
    }

    /// @notice Sets the admin for an integration in storage.
    /// @param integration The integration address to set the admin for.
    /// @param newAdmin The new admin of the integration.
    function _setIntegrationAdmin(address integration, address newAdmin) internal {
        address oldAdmin = _state().integrationToState[integration].admin;
        _state().integrationToState[integration].admin = newAdmin;
        emit IntegrationAdminTransferred(integration, oldAdmin, newAdmin);
    }

    /// @notice Sets the protection status for a function in an integration in storage.
    /// @param integration The integration address to set the protection status for.
    /// @param fnSelector The function selector belonging to `integration` to set the protection status for.
    /// @param isEnabled The new protection status for the function, where `true` means function protection is enabled.
    function _setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) internal {
        _state().integrationToFunctionProtectionStatus[integration][fnSelector] = isEnabled;
        emit FunctionProtectionStatusUpdated(integration, fnSelector, isEnabled);
    }

    /// @notice Sets the registration status for an integration in storage.
    /// @param integration The integration address to set the registration status for.
    /// @param status The new registration status for the integration, including the selector and protection status.
    function _setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) internal {
        _state().integrationToState[integration].registrationStatus = status;
        emit IntegrationRegistrationStatusUpdated(integration, status);
    }

    /// @notice Sets the installed module in storage.
    /// @param moduleId The module ID to set the module for, derived from the abi.encoded hash of the version.
    /// @param moduleAddress The new module address.
    /// @param version The version of the module.
    function _setModuleInstalled(bytes16 moduleId, address moduleAddress, string memory version) internal {
        _state().idToModules[moduleId] = moduleAddress;
        emit RouterModuleInstalled(moduleId, moduleAddress, version);
    }

    /// @notice Sets the used registrar signature hash in storage.
    /// @param signatureHash The keccak256 hash of the ECDSA signature.
    function _setUsedRegistrationSignatureHash(bytes32 signatureHash) internal {
        _state().usedRegistrarSignatureHashes[signatureHash] = true;
        emit UsedRegistrationSignatureHash(signatureHash);
    }

    /// @notice Sets a module as deprecated in storage.
    /// @param moduleId The module ID to set as deprecated.
    /// @param version The version of the module.
    function _setModuleVersionDeprecated(bytes16 moduleId, string memory version) internal {
        _state().deprecatedModules[moduleId] = true;
        emit RouterModuleDeprecated(moduleId, _state().idToModules[moduleId], version);
    }

    /*//////////////////////////////////////////////////////////////
        DELETE
    //////////////////////////////////////////////////////////////*/

    /// @notice Removes the pending integration admin from storage.
    /// @dev Provides a small gas refund.
    /// @param integration The integration address to remove the pending admin for.
    function _deleteIntegrationPendingAdmin(address integration) internal {
        address pendingAdmin = _state().integrationToPendingAdmin[integration];
        delete _state().integrationToPendingAdmin[integration];
        emit IntegrationPendingAdminRemoved(integration, pendingAdmin);
    }

    /// @notice Removes an installed module from storage.
    /// @dev Invoked when a module is uninstalled. Provides a small gas refund.
    /// @param moduleId The ID belonging to the module to remove.
    function _deleteInstalledModule(bytes16 moduleId) internal {
        delete _state().idToModules[moduleId];
        emit RouterModuleRemoved(moduleId);
    }
}
