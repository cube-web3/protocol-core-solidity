// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICube3Registry } from "@src/interfaces/ICube3Registry.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { ProtocolAdminRoles } from "@src/common/ProtocolAdminRoles.sol";
import {ProtocolEvents} from "@src/common/ProtocolEvents.sol";

/// @title Cube3Registry
/// @notice Contract containing logic for the storage and management of integration Signing
/// Authorities.
/// @dev See {ICube3Registry} for documentation.
/// Notes:
/// - In the event of a catestrophic breach of the KMS, the registry contract can be deprecated and replaced
/// by a new version.
contract Cube3Registry is AccessControl, ICube3Registry, ProtocolAdminRoles, ProtocolEvents {
    /*//////////////////////////////////////////////////////////////
            SIGNING AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    // stores the signing authority for each integration contract, tied to the active _invalidationNonce
    mapping(address integration => address signingAuthority) internal integrationToSigningAuthority;

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        // The deployer is the EOA who initiated the transaction, and is the account that will revoke
        // it's own access permissions and add new ones immediately following deployment.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
            KEY MANAGER LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3Registry
    function setClientSigningAuthority(
        address integrationContract,
        address clientSigningAuthority
    )
        external
        onlyRole(CUBE3_KEY_MANAGER_ROLE)
    {
        _setClientSigningAuthority(integrationContract, clientSigningAuthority);
    }

    /// @inheritdoc ICube3Registry
    function batchSetSigningAuthority(
        address[] calldata integrations,
        address[] calldata signingAuthorities
    )
        external
        onlyRole(CUBE3_KEY_MANAGER_ROLE)
    {
        // Store the length in memory so we're not continually reading the size from calldata for each iteration.
        uint256 lenIntegrations = integrations.length;

        // TODO: test
        // Checks: make sure there's an authority for each integration provided.
        if (lenIntegrations != signingAuthorities.length) {
            revert ProtocolErrors.Cube3Protocol_ArrayLengthMismatch();
        }

        for (uint256 i; i < lenIntegrations;) {
            // Effects: set the signing authority for the integration.
            _setClientSigningAuthority(integrations[i], signingAuthorities[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ICube3Registry
    function revokeSigningAuthorityForIntegration(address integration) external onlyRole(CUBE3_KEY_MANAGER_ROLE) {
        _revokeSigningAuthorityForIntegration(integration);
    }

    /// @inheritdoc ICube3Registry
    function batchRevokeSigningAuthoritiesForIntegrations(address[] calldata integrationsToRevoke)
        external
        onlyRole(CUBE3_KEY_MANAGER_ROLE)
    {
        // Store the length in memory so we're not continually reading the size from calldata for each iteration.
        uint256 len = integrationsToRevoke.length;
        for (uint256 i; i < len;) {
            // Effects: revoke the signing authority for the integration at the current index.
            _revokeSigningAuthorityForIntegration(integrationsToRevoke[i]);
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/
    /// @dev override for AccessControlUpgradeable
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(ICube3Registry).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
            UTILITY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // TODO: rename
    /// @notice Sets the signing authority for an integration.
    /// @dev Encapsulates the setter for reusability.
    /// @param integration The contract address of the integration to set the `authority` for.
    /// @param authority The address of the signing authority.
    function _setClientSigningAuthority(address integration, address authority) internal {
        // Checks: check the integration address is a valid address.
        if (integration == address(0)) {
            revert ProtocolErrors.Cube3Protocol_InvalidIntegration();
        }

        // Checks: check the signing authority is a valid address.
        if (authority == address(0)) {
            revert ProtocolErrors.Cube3Registry_InvalidSigningAuthority();
        }

        // Effects: Set the signing authority for the integration.
        integrationToSigningAuthority[integration] = authority;

        // Log: the updated signing authority for the integration.
        emit SigningAuthorityUpdated(integration, authority);
    }

    /// @notice Revokes the signing authority for an integration.
    /// @dev encapsulates revocation code for reusability.
    /// @param integration The integration to revoke the signing authority for.
    function _revokeSigningAuthorityForIntegration(address integration) internal {
        // Retrieve the integration's signing authority from storage.
        address revokedSigner = integrationToSigningAuthority[integration];

        // Checks: make sure the integration has a signing authority.
        if (revokedSigner == address(0)) {
            revert ProtocolErrors.Cube3Registry_NonExistentSigningAuthority();
        }

        // Effects: remove the signing authority for the integration. Also provides
        // a small gas refund.
        delete integrationToSigningAuthority[integration];

        // Log: the address of the revoked signing authority.
        emit SigningAuthorityRevoked(integration, revokedSigner);
    }

    /*//////////////////////////////////////////////////////////////
            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3Registry
    function getSigningAuthorityForIntegration(address integration) external view returns (address) {
        return integrationToSigningAuthority[integration];
    }
}
