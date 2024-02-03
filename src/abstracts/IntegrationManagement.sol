// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { ERC165CheckerUpgradeable } from
    "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import { ICube3Module } from "../interfaces/ICube3Module.sol";
import { ICube3Registry } from "../interfaces/ICube3Registry.sol";

import { Structs } from "../common/Structs.sol";
import { RouterStorage } from "./RouterStorage.sol";
import { SignatureUtils } from "../libs/SignatureUtils.sol";
import { AddressUtils } from "../libs/AddressUtils.sol";

/// @dev This contract contains all the logic for managing customer integrations
abstract contract IntegrationManagement is AccessControlUpgradeable, RouterStorage {
    using SignatureUtils for bytes;
    using AddressUtils for address;

    /*//////////////////////////////////////////////////////////////
            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyIntegrationAdmin(address integration) {
        require(getIntegrationAdmin(integration) == msg.sender, "TODO: Not admin");
        _;
    }

    modifier onlyPendingIntegrationAdmin(address integration) {
        require(getIntegrationPendingAdmin(integration) == msg.sender, "TODO: Not pending admin");
        _;
    }

    /*//////////////////////////////////////////////////////////////
            INTEGRATION MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /// @dev Begins the 2 step transfer of admin rights for an integration contract.
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

    /// @dev Protection can only be enabled for a function if the status is REGISTERED
    /// @dev Can only be called by the integration's admin
    function updateFunctionProtectionStatus(
        address integration,
        Structs.FunctionProtectionStatusUpdate[] calldata updates
    )
        external
        onlyIntegrationAdmin(integration)
    {
        bool isRegisteredIntegration = getIntegrationStatus(integration) == Structs.RegistrationStatusEnum.REGISTERED;

        uint256 len = updates.length;
        for (uint256 i; i < len;) {
            Structs.FunctionProtectionStatusUpdate calldata update = updates[i];
            // Checks only an integration that's REGISTERED can enable protection for a function and utilize the
            // protocol.
            // However, if an integration has protections enabled, we allow them to disable them even if REVOKED.
            if (update.protectionEnabled) {
                require(isRegisteredIntegration, "TODO: not registered");
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
    /// @dev Does not prevent an EOA from calling this function, as registration takes place in an integration's
    /// constructor
    ///      and codesize will be zero.
    function initiateIntegrationRegistration(address admin_) external returns (bool) {
        require(admin_ != address(0), "TODO: zero address");
        require(getIntegrationAdmin(msg.sender) == address(0), "TODO: Already registered");
        _setIntegrationAdmin(msg.sender, admin_);
        _setIntegrationRegistrationStatus(msg.sender, Structs.RegistrationStatusEnum.PENDING);
        return true;
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
        // Checks: the integration being registered is a valid address
        require(integration != address(0), "TODO zero address");

        // Checks: the account that pre-registered is not an EOA.
        integration.assertIsContract();

        // Checks: the integration has been pre-registered and the status is in the PENDING state
        require(getIntegrationStatus(integration) == Structs.RegistrationStatusEnum.PENDING, "GK13: not PENDING");

        // Prevent the same signature from being reused - replaces the need for blacklisting revoked integrations
        // who might attempt to re-register with the same signature. Use the hash of the signature to avoid malleability
        // issues.
        bytes32 registrarSignatureHash = keccak256(abi.encode(registrarSignature));

        // Checks: the signature has not been used before to register an integrationq
        require(!getRegistrarSignatureHashExists(registrarSignatureHash), "CR13: registrar reuse");

        // TODO: what about the case of multiple registrars
        // Checks: the registry and registrar are valid accounts.
        (address registry, address integrationRegistrar) = fetchSigningAuthorityForIntegrationFromRegistry(integration);
        require(registry != address(0), "TODO: No Registry");
        require(integrationRegistrar != address(0), "TODO: No Registrar");

        // Generate the digest with the integration-specific data. Using `chainid` prevents replay across chains.
        bytes32 digest = keccak256(abi.encodePacked(integration, getIntegrationAdmin(integration), block.chainid));

        // Checks: uses ECDSA recovery to validates the signature.  Reverts if the registrarSignature is invalid.
        registrarSignature.assertIsValidSignature(digest, integrationRegistrar);

        // Effects: marks the registration signature hash as used by setting the entry in the mapping to True.
        _setUsedRegistrationSignatureHash(registrarSignatureHash);

        // Set the function protection status for each selector in the array.
        uint256 numSelectors = enabledByDefaultFnSelectors.length;
        if (numSelectors > 0) {
            for (uint256 i; i < numSelectors;) {
                _setFunctionProtectionStatus(integration, enabledByDefaultFnSelectors[i], true);
                unchecked {
                    ++i;
                }
            }
        }

        _setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REGISTERED);
    }

    /*//////////////////////////////////////////////////////////////
            INTEGRATION ADMINISTRATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function batchSetIntegrationRegistrationStatus(
        address[] calldata integrations,
        Structs.RegistrationStatusEnum[] calldata statuses
    )
        external
        onlyRole(CUBE3_INTEGRATION_ADMIN_ROLE)
    {
        require(integrations.length == statuses.length, "CR05: array length mismatch");
        uint256 len = integrations.length;
        for (uint256 i; i < len;) {
            _updateIntegrationRegistrationStatus(integrations[i], statuses[i]);
            unchecked {
                ++i;
            }
        }
    }

    function setIntegrationRegistrationStatus(
        address integration,
        Structs.RegistrationStatusEnum registrationStatus
    )
        external
        onlyRole(CUBE3_INTEGRATION_ADMIN_ROLE)
    {
        _updateIntegrationRegistrationStatus(integration, registrationStatus);
    }

    /*//////////////////////////////////////////////////////////////
            HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Utility function for returning the integration's signing authority, which is used to validate
    ///      the registrar signature.
    function fetchSigningAuthorityForIntegrationFromRegistry(address integration)
        public
        view
        returns (address registry, address authority)
    {
        registry = getRegistryAddress();
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
        require(integration != address(0), "GK14: zero address");
        require(getIntegrationStatus(integration) != status, "GK06: same status");
        _setIntegrationRegistrationStatus(integration, status);
    }
}
