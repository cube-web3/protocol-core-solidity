// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICube3Registry } from "./interfaces/ICube3Registry.sol";

import { ProtocolErrors } from "./libs/ProtocolErrors.sol";
import { ProtocolAdminRoles } from "./common/ProtocolAdminRoles.sol";

/// @dev See {ICube3Registry}
/// @dev In the event of a catestrophic breach of the KMS, the registry contract will be detached from the module
contract Cube3Registry is AccessControl, ICube3Registry, ProtocolAdminRoles {
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

    function setClientSigningAuthority(
        address integrationContract,
        address clientSigningAuthority
    )
        external
        onlyRole(CUBE3_KEY_MANAGER_ROLE)
    {
        _setClientSigningAuthority(integrationContract, clientSigningAuthority);
    }

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

    function revokeSigningAuthorityForIntegration(address integration) external onlyRole(CUBE3_KEY_MANAGER_ROLE) {
        _revokeSigningAuthorityForIntegration(integration);
    }

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
    /// @dev reusable utility function that sets the authority, checks addresses, and emits the event
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

    /// @dev encapsulates revocation code to be reusable
    function _revokeSigningAuthorityForIntegration(address _integration) internal {
        // Retrieve the integration's signing authority from storage.
        address revokedSigner = integrationToSigningAuthority[_integration];

        // Checks: make sure the integration has a signing authority.
        if (revokedSigner == address(0)) {
            revert ProtocolErrors.Cube3Registry_NonExistentSigningAuthority();
        }

        // Effects: remove the signing authority for the integration. Also provides
        // a small gas refund.
        delete integrationToSigningAuthority[_integration];

        // Log: the address of the revoked signing authority.
        emit SigningAuthorityRevoked(_integration, revokedSigner);
    }

    /*//////////////////////////////////////////////////////////////
            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getSigningAuthorityForIntegration(address integration) external view returns (address) {
        return integrationToSigningAuthority[integration];
    }
}
