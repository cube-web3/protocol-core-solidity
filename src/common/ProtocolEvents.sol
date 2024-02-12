// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Structs } from "./Structs.sol";

// TODO: maybe this becomes an interface

/// @title ProtocolEvents
/// @notice Defines the collective events used throughout the Protocol.
abstract contract ProtocolEvents {

    /// @notice Emitted when a CUBE3 admin installs a new module.
    /// @param moduleId The module's computed ID.
    /// @param moduleAddress The contract address of the module.
    /// @param version A string representing the modules version in the form `<module_name>-<semantic_version>`.
    event RouterModuleInstalled(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);

    /// @notice Emitted when a Cube3 admin deprecates an installed module.
    /// @param moduleId The computed ID of the module that was deprecated.
    /// @param moduleAddress The contract address of the module that was deprecated.
    /// @param version The human-readable version of the deprecated module.
    event RouterModuleDeprecated(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);

    /// @notice Emitted when a module is removed from the Router's storage.
    /// @dev Emitted during the uninstallation of a module.
    /// @param moduleId The computed ID of the module being installed.
    event RouterModuleRemoved(bytes16 indexed moduleId);

    /// @notice Emitted when committing a used registration signature hash to storage.
    /// @param signatureHash The keccak256 hash of the ECDSA signature.
    event UsedRegistrationSignatureHash(bytes32 indexed signatureHash);

    /// @notice Emitted when the registration status of an integration is updated.
    /// @dev Provides an audit trail for changes in the registration status of integrations, enhancing the protocol's governance transparency.
    /// @param integration The address of the integration contract.
    /// @param status The new registration status, represented as an enum.
    event IntegrationRegistrationStatusUpdated(address indexed integration, Structs.RegistrationStatusEnum status);

    /// @notice Emitted when the admin address of an integration is updated.
    /// @param integration The address of the integration contract whose admin is being updated.
    /// @param admin The new admin address for the integration.
    event IntegrationAdminUpdated(address indexed integration, address indexed admin);

    /// @notice Emitted when a pending admin for an integration is removed.
    /// @dev Indicates the successful transfer of the admin account.
    /// @param integration The address of the integration contract.
    /// @param pendingAdmin The address of the pending admin being removed.
    event IntegrationPendingAdminRemoved(address indexed integration, address indexed pendingAdmin);

    /// @notice Emitted at the start of an admin transfer for an integration, signaling the initiation of admin change.
    /// @param integration The address of the integration contract undergoing admin transfer.
    /// @param oldAdmin The current admin address before the transfer.
    /// @param pendingAdmin The address of the pending admin set to receive admin privileges.
    event IntegrationAdminTransferStarted(
        address indexed integration, address indexed oldAdmin, address indexed pendingAdmin
    );

    /// @notice Emitted when the admin transfer for an integration is completed.
    /// @param integration The address of the integration.
    /// @param oldAdmin The previous admin address before the transfer.
    /// @param newAdmin The new admin address after the transfer.
    event IntegrationAdminTransferred(address indexed integration, address indexed oldAdmin, address indexed newAdmin);

    /// @notice Emitted when the protection status of a function in an integration is updated.
    /// @dev This event logs changes to whether or not the Protocol is utilized for calls to the designated function.
    /// @param integration The address of the integration contract.
    /// @param selector The function selector (first 4 bytes of the keccak256 hash of the function signature) whose protection status is updated.
    /// @param status The new protection status; `true` for protected and `false` for unprotected.
    event FunctionProtectionStatusUpdated(address indexed integration, bytes4 indexed selector, bool status);

    /// @notice Emitted when protocol-wide configuration settings are updated.
    /// @param registry The address of the protocol registry contract where configurations are updated.
    /// @param paused A boolean indicating the new paused state of the protocol; `true` for paused and `false` for unpaused.
    event ProtocolConfigUpdated(address indexed registry, bool paused);

    /// @notice Emitted when the protocol registry is removed, indicating a significant protocol-wide operation, possibly for upgrades or migration.
    /// @dev Until a new protocol is set, new integration registrations will be blocked.
    event ProtocolRegistryRemoved();

}
