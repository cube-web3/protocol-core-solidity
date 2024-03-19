// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title Structs
/// @notice Defines shared datastructures and enums for the Protocol.
abstract contract Structs {
    /// @notice  Defines the status of the integration and its relationship with the CUBE3 Protocol.
    ///
    /// Notes:
    /// - Defines the integration's level of access to the Protocol.
    /// - An integration can only attain the REGISTERED status receiving a registration signature from the CUBE3
    /// service off-chain.
    ///
    /// @param UNREGISTERED The integration technically does not exist as it has not been pre-registered with the
    /// protocol.
    /// @param PENDING The integration has been pre-registered with the protocol, but has not completed registration.
    /// @param REGISTERED The integration has completed registration with the protocol using the signature provided by
    /// the off-chain CUBE3 service and is permissioned to update the protection status of functions.
    /// @param REVOKED The integration no longer has the ability to enable function protection.
    enum RegistrationStatusEnum {
        UNREGISTERED,
        PENDING,
        REGISTERED,
        REVOKED
    }

    /// @notice Structure for storing the state of an integration.
    /// @param admin The admin account of the integration is represents.
    /// @param registration The state of the integration's registration and thus its relationship with the Protocol.
    struct IntegrationState {
        address admin;
        RegistrationStatusEnum registrationStatus;
    }

    /// @notice Represents a request to update the protection status of a specific function within an integration.
    /// @param fnSelector The function selector (first 4 bytes of the keccak256 hash of the function signature) targeted
    /// for protection status update.
    /// @param protectionEnabled Boolean indicating whether the protection for the specified function is to be enabled
    /// (true) or disabled (false).
    struct FunctionProtectionStatusUpdate {
        bytes4 fnSelector;
        bool protectionEnabled;
    }

    /// @notice Holds the configuration settings of the Protocol.
    /// @param registry The address of the Protocol's registry contract, central to configuration and integration
    /// management.
    /// @param paused Boolean indicating the operational status of the Protocol; when true, the Protocol is paused,
    /// disabling certain operations.
    struct ProtocolConfig {
        address registry;
        bool paused;
    }

    /// @notice Aggregates essential components of a top-level call to any of the Protocol's security modules.
    /// @param msgSender The original sender of the top-level transaction.
    /// @param integration The address of the integration contract being interacted with.
    /// @param msgValue The amount of Ether (in wei) sent with the call.
    /// @param calldataDigest A digest of the call data, providing an integrity check and identity for the transaction's
    /// calldata.
    struct TopLevelCallComponents {
        address msgSender;
        address integration;
        uint256 msgValue;
        bytes32 calldataDigest;
    }
}
