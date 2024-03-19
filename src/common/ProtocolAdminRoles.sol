// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title ProtocolAdminRoles
/// @notice Defines privileged roles for controlled access to Protocol functions.
abstract contract ProtocolAdminRoles {
    /*//////////////////////////////////////////////////////////////
        ROLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Privileged role for making protocol-level changes.
    bytes32 public constant CUBE3_PROTOCOL_ADMIN_ROLE = keccak256("CUBE3_PROTOCOL_ADMIN_ROLE");

    /// @notice Privileged role for making integration-level changes.
    bytes32 public constant CUBE3_INTEGRATION_MANAGER_ROLE = keccak256("CUBE3_INTEGRATION_MANAGER_ROLE");

    /// @notice EOA acting on behalf of the KMS, responsible for managing signing authorities
    bytes32 public constant CUBE3_KEY_MANAGER_ROLE = keccak256("CUBE3_KEY_MANAGER_ROLE");
}
