// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

/// @title ICube3Registry
/// @notice This contract serves as a registry for storing and managing the signing authorities
///         assigned to specific Cube3 customer integrations.
/// Notes:
/// - A "signing authority" is the EOA address belonging to the private key from the keypair that
/// generates the signature of the secure payload supplied by the Risk API.
/// - Events are defined in {ProtocolEvents}
interface ICube3Registry {

    /// @notice Sets or updates the signing authority address for an integration contract.
    ///
    /// @dev Emits a {SigningAuthorityUpdated} event.
    ///
    /// Notes:
    /// - External wrapper for the {Cube3Registry-_setClientSigningAuthority}
    /// - 
    ///
    /// Requirements:
    /// - `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
    /// - `integrationContract` cannot be the zero address.
    /// - `clientSigningAuthority` cannot be the zero address.
    ///
    /// @param integrationContract The contract address of the integration.
    /// @param clientSigningAuthority The public address generated for the integration's private-public key-pair
    /// managed by the CUBE3 KMS.
    function setClientSigningAuthority(address integrationContract, address clientSigningAuthority) external;

    /// @notice Sets signing authorities for multiple integration contracts
    ///
    /// @dev Emits an {SigningAuthorityUpdated} for integration.
    ///
    /// Notes:
    /// - Can lead to out-of-gas errors due to no array  length check; use discretion when calling.
    /// - 
    ///
    /// Requirements:
    /// - `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
    /// - `integrations` and `signingAuthorities` arrays must be of equal length.
    /// - No address in the `integrations` array can be the zero address.
    /// - No address in the `signingAuthorities` array can be the zero address.
    ///
    /// @param integrations The addresses of the integration contracts.
    /// @param signingAuthorities The addresses of the signing authorities, indexed to match the `integrations` array.
    function batchSetSigningAuthority(
        address[] calldata integrations,
        address[] calldata signingAuthorities
    )
        external;

    /// @notice Revokes a signing authority for a specified integration contract.
    ///
    /// @dev Emits a {SigningAuthorityRevoked} event.
    ///
    /// Notes:
    /// - This operation is irreversible through this function call.
    /// - Removes the signing authority from the `integrationToSigningAuthority` map.
    ///
    /// Requirements:
    /// - `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
    /// - The signing authority for the `integration` must have been set previously.
    ///
    /// @param integration The integration contract's address to have its signing authority revoked.
    function revokeSigningAuthorityForIntegration(address integration) external;

    /// @notice Revokes multiple signing authorities for the integration contracts provided.
    ///
    /// @dev Emits a {SigningAuthorityRevoked} event for each revocation.
    ///
    /// Notes:
    /// - This operation is irreversible through this function call.
    /// - Removes each signing authority from the `integrationToSigningAuthority` map.
    ///
    /// Requirements:
    /// - `msg.sender` must have the CUBE3_KEY_MANAGER_ROLE role.
    /// - The signing authority for each integration must have been set previously.
    ///
    /// @param integrationsToRevoke Array containing the integration contracts to revoke
    /// signing authorities for.
    function batchRevokeSigningAuthoritiesForIntegrations(address[] calldata integrationsToRevoke) external;

    /// @notice Retrieves the signing authority's address for the provided `integration`.
    /// Notes:
    /// - Each integration contract has a unique signature authority managed by Cube3's KMS.
    /// - Will return address(0) for a non-existent authority, so it's up to the caller
    /// to handle such a case accordingly.
    /// @param integration The ingtegration contract's address.
    /// @return The signing authority (account address) of the authority's private-public keypair.
    function getSigningAuthorityForIntegration(address integration) external view returns (address);
}
