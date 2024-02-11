// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ICube3Module } from "../interfaces/ICube3Module.sol";
import { ICube3Registry } from "../interfaces/ICube3Registry.sol";
import { Structs } from "../common/Structs.sol";
import { RouterStorage } from "./RouterStorage.sol";
import { SignatureUtils } from "../libs/SignatureUtils.sol";
import { AddressUtils } from "../libs/AddressUtils.sol";

import { ProtocolConstants } from "../common/ProtocolConstants.sol";

import { ProtocolErrors } from "../libs/ProtocolErrors.sol";

/// @dev This contract contains all the logic for managing customer integrations
abstract contract IntegrationManagement is AccessControlUpgradeable, RouterStorage {
    using SignatureUtils for bytes;
    using AddressUtils for address;

    /*//////////////////////////////////////////////////////////////
            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyIntegrationAdmin(address integration) {
        if (getIntegrationAdmin(integration) != msg.sender) {
            revert ProtocolErrors.Cube3Router_CallerNotIntegrationAdmin();
        }
        _;
    }

    modifier onlyPendingIntegrationAdmin(address integration) {
        if (getIntegrationPendingAdmin(integration) != msg.sender) {
            revert ProtocolErrors.Cube3Router_CallerNotPendingIntegrationAdmin();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
            INTEGRATION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @dev Begins the 2 step transfer the admin account for an integration contract.
    /// @dev Can only be called by the integration's existing admin.
    function transferIntegrationAdmin(
        address integration,
        address newAdmin
    )
        external
        onlyIntegrationAdmin(integration)
    {
        _setPendingIntegrationAdmin(integration, msg.sender, newAdmin);
    }

    /// @dev Facilitates tranfer of admin rights for an integration contract.
    /// @dev Called by the account accepting the admin rights.
    function acceptIntegrationAdmin(address integration) external onlyPendingIntegrationAdmin(integration) {
        _setIntegrationAdmin(integration, msg.sender);
        _deleteIntegrationPendingAdmin(integration); // gas-saving
    }

    /// @dev Protection can only be enabled for a function if the status is REGISTERED.
    /// @dev Can only be called by the integration's admin.
    /// @dev Only an integration that has pre-registered will have an assigned admin, so there's no
    ///      need to check if the status is UNREGISTERED.
    /// @dev An integration that's had its registration status revoked can only disable protection.
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

    /// @dev Called by integration contract during construction, thus the integration contract is `msg.sender`.
    /// @dev We cannot restrict who calls this function, including EOAs, however an integration has no
    ///      access to the protocol until `registerIntegrationWithCube3` is called by the integration admin, for
    ///      which a registrarSignature is required and must be signed by the integration's signing authority via CUBE3.
    /// @dev Only a contract who initiated registration can complete registration via codesize check.
    function initiateIntegrationRegistration(address admin_) external returns (bytes32) {
        // Checks: the integration admin account provided is a valid address.
        if (admin_ == address(0)) {
            revert ProtocolErrors.Cube3Router_InvalidIntegrationAdmin();
        }

        // Checks: the admin is the zero address, meaning the integration has not been registered previously.
        if (getIntegrationAdmin(msg.sender) != address(0)) {
            revert ProtocolErrors.Cube3Router_IntegrationAdminAlreadyInitialized();
        }

        // Effects: set the admin account for the integration.
        _setIntegrationAdmin(msg.sender, admin_);

        // Effects: set the integration's registration status to PENDING.
        _setIntegrationRegistrationStatus(msg.sender, Structs.RegistrationStatusEnum.PENDING);

        // TODO: might be expecting another value
        return PRE_REGISTRATION_SUCCEEDED;
    }

    /// @dev Can only be called by the integration admin set in `initiateIntegrationRegistration`.
    /// @dev Passing an empty array of selectors to enable none by default.
    /// @dev Only a contract who initiated registration can complete registration via codesize check.
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
                _setFunctionProtectionStatus(integration, tempSelector , true);
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

    /// @dev Can be used to revoke an integration's registration status, preventing it from enabling function protection
    /// and blocking access to the protocol by skipping protection checks.
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

    /// @dev Utility function for returning the integration's signing authority, which is used to validate
    /// the registrar signature. If the registry is not set, the function will return the zero address as the signing
    /// authority. It is up to the module to handle this case.
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
        authority = ICube3Registry(registry).getSignatureAuthorityForIntegration(integration);
    }

    /// @dev Updates the integration status for an integration or an integration's proxy.
    /// @dev Only accessible by the Cube3Router contract, allowing changes from, and to, any state
    /// @dev Prevents the status from being set to the same value.
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
