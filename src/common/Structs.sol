// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

// TODO: rename structs and enums
// TODO: maybe DataSchema
abstract contract Structs {
    /// @notice  Defines the state of the integration's registration status.
    /// @dev     RegistrationStatusEnum refers to the integration's relationship with the CUBE3 protocol.
    /// @dev     An integration can only register with the protocol by receiving a registration signature from the CUBE3
    /// service off-chain.
    /// @param   UNREGISTERED The integration technically does not exist as it has not been pre-registered with the
    /// protocol.
    /// @param   PENDING The integration has been pre-registered with the protocol, but has not completed registration.
    /// @param   REGISTERED The integration has completed registration with the protocol using the signature provided by
    /// the off-chain CUBE3 service
    ///          and is permissioned to update the protection status of functions.
    /// @param   REVOKED The integration no longer has the ability to enable function protection.
    enum RegistrationStatusEnum {
        UNREGISTERED,
        PENDING,
        REGISTERED,
        REVOKED
    }

    /// @notice Defines the state of the integration's state in relation to the protocol.
    // TODO: Look into using a bloom filter here
    struct IntegrationState {
        address admin; // 20 bytes
        RegistrationStatusEnum registrationStatus; // 1 byte
    }

    struct FunctionProtectionStatusUpdate {
        bytes4 fnSelector;
        bool protectionEnabled;
    }

    struct ProtocolConfig {
        address registry;
        bool paused;
    }

    struct TopLevelCallComponents {
        address msgSender;
        address integration;
        uint256 msgValue;
        bytes32 calldataDigest;
    }
}
