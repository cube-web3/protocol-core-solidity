// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Structs } from "../common/Structs.sol";
import { ProtocolEvents } from "../common/ProtocolEvents.sol";

import { ProtocolAdminRoles } from "../common/ProtocolAdminRoles.sol";
import { ProtocolConstants } from "../common/ProtocolConstants.sol";

struct Cube3State {
    Structs.ProtocolConfig protocolConfig;
    /*//////////////////////////////////////////////////////////////
        MODULE STORAGE
    //////////////////////////////////////////////////////////////*/

    // stores module IDs mapped to their corresponding module contract addresses
    mapping(bytes16 => address) idToModules;
    /*//////////////////////////////////////////////////////////////
        INTEGRATION MANAGER STORAGE
    //////////////////////////////////////////////////////////////*/

    // mapping of integration_address => pending_admin_address, used as part of a two step
    // transfer of admin privileges for an integration
    mapping(address => address) integrationToPendingAdmin;
    // mapping of integration_address => integration_state, where an integration's state stores
    // its admin address and registration status
    mapping(address => Structs.IntegrationState) integrationToState;
    // mapping of integration_address => (mapping of function_selector => protection_status)
    mapping(address => mapping(bytes4 => bool)) integrationToFunctionProtectionStatus;
    // store a hash of the used registrar signature to prevent re-registration in the event of a revocation
    // replaces the need for an onchain blacklist, as the CUBE3 service will not issue a registarSignature to a revoked
    // integration
    mapping(bytes32 => bool) usedRegistrarSignatureHashes; // abi.encode(signature) => used
}

/// @dev This contract utilizes namespaced storage layout (ERC-7201). All storage access happens via
///      the `_state()` function, which returns a storage pointer to the `Cube3State` struct.  Storage variables
///      can only be accessed via dedicated getter and setter functions.
abstract contract RouterStorage is ProtocolEvents, ProtocolAdminRoles {
    /*//////////////////////////////////////////////////////////////
        STORAGE
    //////////////////////////////////////////////////////////////*/

    // keccak256(abi.encode(uint256(keccak256("cube3.router.storage")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 private constant CUBE3_ROUTER_STORAGE_LOCATION =
        0x965086ef32785f3c2d215dde11368175b9856558874805a1f295cdb684eea500;

    /// @custom:storage-location cube3.router.storage
    function _state() internal pure returns (Cube3State storage state) {
        assembly {
            state.slot := CUBE3_ROUTER_STORAGE_LOCATION
        }
    }

    /*//////////////////////////////////////////////////////////////
        GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Gets the protection status of an integration contract's function using the selector.
    function getIsIntegrationFunctionProtected(address integration, bytes4 fnSelector) public view returns (bool) {
        return _state().integrationToFunctionProtectionStatus[integration][fnSelector];
    }

    /// @notice gets whether the integration has had its registration status revoked
    function getIntegrationStatus(address integration) public view returns (Structs.RegistrationStatus) {
        return _state().integrationToState[integration].registrationStatus;
    }

    /// @notice gets whether the `account` provided is the pending admin for `integration`
    function getIntegrationPendingAdmin(address integration) public view returns (address) {
        return _state().integrationToPendingAdmin[integration];
    }

    /// @notice gets the whether the `account` provided is the admin for `integration`
    function getIntegrationAdmin(address integration) public view returns (address) {
        return _state().integrationToState[integration].admin;
    }

    /// @notice gets whether the protocol is paused
    function getIsProtocolPaused() public view returns (bool) {
        return _state().protocolConfig.paused;
    }

    function getModuleAddressById(bytes16 moduleId) public view returns (address) {
        return _state().idToModules[moduleId];
    }

    function getRegistrarSignatureHashExists(bytes32 signatureHash) public view returns (bool) {
        return _state().usedRegistrarSignatureHashes[signatureHash];
    }

    function getProtocolConfig() external view returns (Structs.ProtocolConfig memory) {
        return _state().protocolConfig;
    }

    function getRegistryAddress() public view returns (address) {
        return _state().protocolConfig.registry;
    }

    /*//////////////////////////////////////////////////////////////
        SETTERS
    //////////////////////////////////////////////////////////////*/

    function _setProtocolConfig(address registry, bool isPaused) internal {
        _state().protocolConfig = Structs.ProtocolConfig(registry, isPaused);
        emit ProtocolConfigUpdated(registry, isPaused);
    }

    function _setPendingIntegrationAdmin(address integration, address pendingAdmin) internal {
        _state().integrationToPendingAdmin[integration] = pendingAdmin;
        emit IntegrationAdminTransferStarted(msg.sender, pendingAdmin);
    }

    function _setIntegrationAdmin(address integration, address newAdmin) internal {
        address oldAdmin = _state().integrationToState[integration].admin;
        _state().integrationToState[integration].admin = newAdmin;
        emit IntegrationAdminTransferred(oldAdmin, newAdmin);
    }

    function _setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) internal {
        _state().integrationToFunctionProtectionStatus[integration][fnSelector] = isEnabled;
        emit FunctionProtectionStatusUpdated(integration, fnSelector, isEnabled);
    }

    function _setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatus status) internal {
        _state().integrationToState[integration].registrationStatus = status;
        emit IntegrationRegistrationStatusUpdated(integration, status);
    }

    function _setModuleInstalled(bytes16 moduleId, address moduleAddress, string memory version) internal {
        _state().idToModules[moduleId] = moduleAddress;
        emit RouterModuleInstalled(moduleId, moduleAddress, version);
    }

    function _setUsedRegistrationSignatureHash(bytes32 signatureHash) internal {
        _state().usedRegistrarSignatureHashes[signatureHash] = true;
        emit UsedRegistrationSignatureHash(signatureHash);
    }

    /*//////////////////////////////////////////////////////////////
        DELETE
    //////////////////////////////////////////////////////////////*/

    function _deleteIntegrationPendingAdmin(address integration) internal {
        address pendingAdmin = _state().integrationToPendingAdmin[integration];
        delete _state().integrationToPendingAdmin[integration];
        emit IntegrationPendingAdminRemoved(integration, pendingAdmin);
    }

    function _deleteInstalledModule(
        bytes16 moduleId,
        address deprecatedModuleAddress,
        string memory version
    )
        internal
    {
        delete _state().idToModules[moduleId];
        emit RouterModuleDeprecated(moduleId, deprecatedModuleAddress, version);
    }
}
