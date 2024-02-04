// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract ProtocolAdminRoles {
    /*//////////////////////////////////////////////////////////////
        ROLES
    //////////////////////////////////////////////////////////////*/

    // Privileged role for making protocol-level changes.
    bytes32 public constant CUBE3_PROTOCOL_ADMIN_ROLE = keccak256("CUBE3_PROTOCOL_ADMIN_ROLE");

    // Privileged role for making integration-level changes.
    bytes32 public constant CUBE3_INTEGRATION_MANAGER_ROLE = keccak256("CUBE3_INTEGRATION_MANAGER_ROLE");

    // EOA acting on behalf of the KMS, responsible for managing signing authorities
    bytes32 public constant CUBE3_KEY_MANAGER_ROLE = keccak256("CUBE3_KEY_MANAGER_ROLE");
}
