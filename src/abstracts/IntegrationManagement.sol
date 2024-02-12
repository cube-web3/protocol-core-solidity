// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ICube3Module } from "@src/interfaces/ICube3Module.sol";
import { ICube3Registry } from "@src/interfaces/ICube3Registry.sol";
import { ICube3Router } from "@src/interfaces/ICube3Router.sol";
import { RouterStorage } from "@src/abstracts/RouterStorage.sol";
import { ProtocolConstants } from "@src/common/ProtocolConstants.sol";
import { Structs } from "@src/common/Structs.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { SignatureUtils } from "@src/libs/SignatureUtils.sol";
import { AddressUtils } from "@src/libs/AddressUtils.sol";

/// @title IntegrationManagment
/// @notice This contract implements logic for managing integration contracts and their relationship with the protocol.
/// @dev See {ICube3Router} for documentation.
abstract contract IntegrationManagement is ICube3Router, AccessControlUpgradeable, RouterStorage {
    using SignatureUtils for bytes;
    using AddressUtils for address;

    /*//////////////////////////////////////////////////////////////
            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks the caller is the integration admin account of the `integration` contract provided.
    modifier onlyIntegrationAdmin(address integration) {
        if (getIntegrationAdmin(integration) != msg.sender) {
            revert ProtocolErrors.Cube3Router_CallerNotIntegrationAdmin();
        }
        _;
    }

    /// @notice Checks the caller is the pending integration admin account of the `integration` contract provided.
    modifier onlyPendingIntegrationAdmin(address integration) {
        if (getIntegrationPendingAdmin(integration) != msg.sender) {
            revert ProtocolErrors.Cube3Router_CallerNotPendingIntegrationAdmin();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
            INTEGRATION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3Router
    function transferIntegrationAdmin(
        address integration,
        address newAdmin
    )
        external
        onlyIntegrationAdmin(integration)
    {
        _setPendingIntegrationAdmin(integration, msg.sender, newAdmin);
    }

    /// @inheritdoc ICube3Router
    function acceptIntegrationAdmin(address integration) external onlyPendingIntegrationAdmin(integration) {
        _setIntegrationAdmin(integration, msg.sender);
        _deleteIntegrationPendingAdmin(integration); // small gas refund
    }

    /// @inheritdoc ICube3Router
    function updateFunctionProtectionStatus(
        address integration,
        Structs.FunctionProtectionStatusUpdate[] calldata updates
    )
        external
        onlyIntegrationAdmin(integration)
    {
        // Checks: the integration has completed the registration step.
        Structs.RegistrationStatusEnum status = getIntegrationStatus(integration);
        if (status == Structs.RegistrationStatusEnum.PENDING) {
            revert ProtocolErrors.Cube3Router_IntegrationRegistrationNotComplete();
        }

        // load onto the stack to save gas
        bool isRegistrationRevoked = status == Structs.RegistrationStatusEnum.REVOKED;
        uint256 len = updates.length;

        for (uint256 i; i < len;) {
            Structs.FunctionProtectionStatusUpdate calldata update = updates[i];
            // Checks: only an integration that's REGISTERED can enable protection for a function and utilize the
            // protocol.  However, if an integration has protections enabled, we allow them to disable them even if
            // REVOKED.
            if (update.protectionEnabled && isRegistrationRevoked) {
                revert ProtocolErrors.Cube3Router_IntegrationRegistrationRevoked();
            }

            // Effects: updates the function protection status of the integration's function using the selector.
            _setFunctionProtectionStatus(integration, update.fnSelector, update.protectionEnabled);
            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
            INTEGRATION REGISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3Router
    function initiateIntegrationRegistration(address initialAdmin) external returns (bytes32) {
        // Checks: the integration admin account provided is a valid address.
        if (initialAdmin == address(0)) {
            revert ProtocolErrors.Cube3Router_InvalidIntegrationAdmin();
        }

        // Checks: the admin is the zero address, meaning the integration has not been registered previously.
        if (getIntegrationAdmin(msg.sender) != address(0)) {
            revert ProtocolErrors.Cube3Router_IntegrationAdminAlreadyInitialized();
        }

        // Effects: set the admin account for the integration.
        _setIntegrationAdmin(msg.sender, initialAdmin);

        // Effects: set the integration's registration status to PENDING.
        _setIntegrationRegistrationStatus(msg.sender, Structs.RegistrationStatusEnum.PENDING);

        return PRE_REGISTRATION_SUCCEEDED;
    }

    /// @inheritdoc ICube3Router
    function registerIntegrationWithCube3(
        address integration,
        bytes calldata registrarSignature,
        bytes4[] calldata enabledByDefaultFnSelectors
    )
        external
        onlyIntegrationAdmin(integration)
    {
        // Checks: the integration being registered is a valid address.
        if (integration == address(0)) {
            revert ProtocolErrors.Cube3Protocol_InvalidIntegration();
        }

        // Checks: the account that pre-registered is not an EOA.
        integration.assertIsContract();

        // Checks: the integration has been pre-registered and the status is in the PENDING state
        if (getIntegrationStatus(integration) != Structs.RegistrationStatusEnum.PENDING) {
            revert ProtocolErrors.Cube3Router_IntegrationRegistrationStatusNotPending();
        }

        // Prevent the same signature from being reused - replaces the need for blacklisting revoked integrations
        // who might attempt to re-register with the same signature. Use the hash of the signature to avoid malleability
        // issues.
        bytes32 registrarSignatureHash = keccak256(registrarSignature);

        // Checks: the signature has not been used before to register an integrationq
        if (getRegistrarSignatureHashExists(registrarSignatureHash)) {
            revert ProtocolErrors.Cube3Router_RegistrarSignatureAlreadyUsed();
        }

        // Checks: the registry and registrar are valid accounts.
        (address registry, address integrationSigningAuthority) =
            fetchRegistryAndSigningAuthorityForIntegration(integration);

        // Checks: the registry has been set.
        if (registry == address(0)) {
            revert ProtocolErrors.Cube3Router_RegistryNotSet();
        }

        // Checks: the integration's signing authority exists.
        if (integrationSigningAuthority == address(0)) {
            revert ProtocolErrors.Cube3Router_IntegrationSigningAuthorityNotSet();
        }

        // Generate the digest with the integration-specific data. Using `chainid` prevents replay across chains.
        bytes32 registrationDigest =
            keccak256(abi.encodePacked(integration, getIntegrationAdmin(integration), block.chainid));

        // Checks: uses ECDSA recovery to validates the signature.  Reverts if the registrarSignature is invalid.
        registrarSignature.assertIsValidSignature(registrationDigest, integrationSigningAuthority);

        // Effects: marks the registration signature hash as used by setting the entry in the mapping to True.
        _setUsedRegistrationSignatureHash(registrarSignatureHash);

        // Place variables on the stack to save gas
        uint256 numSelectors = enabledByDefaultFnSelectors.length;
        bytes4 tempSelector;

        // Update the protection status for each selector provided in the array.
        if (numSelectors > 0) {
            for (uint256 i; i < numSelectors;) {
                tempSelector = enabledByDefaultFnSelectors[i];

                // Checks: the selector being set is not null.
                if (tempSelector == bytes4(0)) {
                    revert ProtocolErrors.Cube3Router_InvalidFunctionSelector();
                }

                // Effects: updates the function protection status of the integration's function using the selector.
                _setFunctionProtectionStatus(integration, tempSelector, true);
                unchecked {
                    ++i;
                }
            }
        }

        // Effects: updates the integration's registration status to REGISTERED.
        _setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REGISTERED);
    }

    /*//////////////////////////////////////////////////////////////
            INTEGRATION ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3Router
    function batchUpdateIntegrationRegistrationStatus(
        address[] calldata integrations,
        Structs.RegistrationStatusEnum[] calldata statuses
    )
        external
        onlyRole(CUBE3_INTEGRATION_MANAGER_ROLE)
    {
        uint256 numIntegrations = integrations.length;

        // Checks: the array lengths are equal.
        if (numIntegrations != statuses.length) {
            revert ProtocolErrors.Cube3Protocol_ArrayLengthMismatch();
        }

        // Interactions: updates the registration status for each integration in the array.
        for (uint256 i; i < numIntegrations;) {
            _updateIntegrationRegistrationStatus(integrations[i], statuses[i]);
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ICube3Router
    function updateIntegrationRegistrationStatus(
        address integration,
        Structs.RegistrationStatusEnum registrationStatus
    )
        external
        onlyRole(CUBE3_INTEGRATION_MANAGER_ROLE)
    {
        _updateIntegrationRegistrationStatus(integration, registrationStatus);
    }

    /*//////////////////////////////////////////////////////////////
            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICube3Router
    function fetchRegistryAndSigningAuthorityForIntegration(address integration)
        public
        view
        returns (address registry, address authority)
    {
        // Get the registry address from storage.
        registry = getRegistryAddress();

        // Checks: the registry exists. If not, return the zero address as the signing authority.
        if (registry == address(0)) {
            return (address(0), address(0));
        }
        authority = ICube3Registry(registry).getSigningAuthorityForIntegration(integration);
    }

    /// @notice Internal helper for performing checks and updating storage for and integration's registration
    /// status.
    /// @dev Cannot set the status for the zero address and prevents the status from being set to the same value.
    function _updateIntegrationRegistrationStatus(
        address integration,
        Structs.RegistrationStatusEnum status
    )
        internal
    {
        // Checks: the integration address is valid.
        if (integration == address(0)) {
            revert ProtocolErrors.Cube3Protocol_InvalidIntegration();
        }

        // Checks: whether the status is the same as the current status.
        if (status == getIntegrationStatus(integration)) {
            revert ProtocolErrors.Cube3Router_CannotSetStatusToCurrentStatus();
        }

        // Effects: updates the integration's registration status.
        _setIntegrationRegistrationStatus(integration, status);
    }
}
