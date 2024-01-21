// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ICube3Registry} from "./interfaces/ICube3Registry.sol";

import {AdminRoles} from "./common/AdminRoles.sol";

/// @dev See {ICube3Registry}
/// @dev In the event of a catestrophic breach of the KMS, the registry contract will be detached from the module
contract Cube3Registry is AccessControl, ICube3Registry, AdminRoles {

    /*//////////////////////////////////////////////////////////////
            SIGNING AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    // stores the signing authority for each integration contract, tied to the active _invalidationNonce
    mapping(address integration => address signingAuthority) internal integrationToSigningAuthority; // integration => signer

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // the deployer is the EOA who initiated the transaction, and is the account that will revoke
        // it's own access permissions and add new ones immediately following deployment
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
            KEY MANAGER LOGIC
    //////////////////////////////////////////////////////////////*/

    function setClientSigningAuthority(address integrationContract, address clientSigningAuthority)
        external
        onlyRole(CUBE3_KEY_MANAGER_ROLE)
    {
        _setClientSigningAuthority(integrationContract, clientSigningAuthority);
    }

    function batchSetSigningAuthority(address[] calldata integrations, address[] calldata signingAuthorities)
        external
        onlyRole(CUBE3_KEY_MANAGER_ROLE)
    {
        // Store the length in memory so we're not continually reading from calldata for each iteration.
        uint256 lenIntegrations = integrations.length;

        // Checks: make sure there's an authority for each integration provided.
        require(lenIntegrations == signingAuthorities.length, "CRG02: length mismatch");
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
        // Store the length in memory so we're not continually reading from calldata for each iteration.
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
    /// @dev made available via AccessControlUpgradeable
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
        require(integration != address(0), "CRG06 invalid integration");

        // Checks: check the signing authority is a valid address.
        require(authority != address(0), "CRG07: invalid signing authority");

        // Effects: Set the signing authority for the integration.
        integrationToSigningAuthority[integration] = authority;

        // Log the authority update.
        emit SigningAuthorityUpdated(integration, authority);
    }

    /// @dev encapsulates revocation code to be reusable
    function _revokeSigningAuthorityForIntegration(address _integration) internal {
        address revokedSigner = integrationToSigningAuthority[_integration];
        require(revokedSigner != address(0), "CRG08: integration not present");
        delete integrationToSigningAuthority[_integration];
        emit SigningAuthorityRevoked(_integration, revokedSigner);
    }

    /*//////////////////////////////////////////////////////////////
            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getSignatureAuthorityForIntegration(address integration) external view returns (address) {
        return integrationToSigningAuthority[integration];
    }

    function getSignatureAuthority(address integration) external view returns (address) {
        return integrationToSigningAuthority[integration];
    }
}
