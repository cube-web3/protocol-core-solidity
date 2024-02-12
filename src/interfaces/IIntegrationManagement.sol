// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Structs } from "@src/common/Structs.sol";
interface IIntegrationManagement {

    /*//////////////////////////////////////////////////////////////////////////
                                Integration Management
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Begins the 2 step transfer process of the admin account for an integration contract.
    ///
    /// @dev Emits an {IntegrationAdminTransferStarted} event.
    ///
    /// Requirements:
    /// - The caller must be the current admin of the integration contract.
    /// - The `newAdmin` must call {acceptIntegrationAdmin} to complete the transfer of privileges.
    ///
    /// @param integration The address of the integration contract the admin accounts belong to.
    /// @param newAdmin The account to transfer the admin role to.
    function transferIntegrationAdmin(address integration, address newAdmin) external;

    /// @notice  Accepts the admin rights for an integration contract and completes the 2 step transfer process.
    ///
    /// @dev Emits {IntegrationAdminTransferred} and {IntegrationPendingAdminRemoved} events.
    ///
    /// Requirements:
    /// - The caller must be the `pendingAdmin` set in the {transferIntegrationAdmin} function.
    ///
    /// @param integration The address of the integration contract the admin accounts belong to.
    function acceptIntegrationAdmin(address integration) external;

    /// @notice Updates the protection status of the functions included in the `updates` array for the
    /// specified `integration`.
    ///
    /// @dev Emits an {FunctionProtectionStatusUpdated} event for each update.
    ///
    /// Notes:
    /// - Only an integration that has completed the pre-registration process will have an assigned admin
    /// account, during which process the registration status is set to PENDING. Thus, there is no need to
    /// perform a check against integrations with an UNREGISTERED status.
    /// - An integration that has had its registration status set to REVOKED no longer has permission to
    /// enable function protection and can only disable protection for existing functions.
    /// - There is no guardrail against enabling protection using a selector that does not match a function signature
    /// on the `integration` contract.
    ///
    /// Requirements:
    /// - Protection for a function can only be enabled if the integration has a REGISTERED status.
    /// - Can only be called by the integration's admin account.
    ///
    /// @param integration The address of the integration contract to update the function protection status for.
    /// @param updates Array of {Structs.FunctionProtectionStatusUpdate} structs which pairs the targeted function's
    /// selector with the desired protection status.
    function updateFunctionProtectionStatus(
        address integration,
        Structs.FunctionProtectionStatusUpdate[] calldata updates
    )
        external;

    /// @notice Initiates the registration of a new integration contract with the CUBE3 protocol.
    ///
    /// @dev Emits {IntegrationAdminTransferred} and {IntegrationRegistrationStatusUpdated} events.
    ///
    /// Notes:
    /// - Called by integration contract from inside its constructor, thus the integration contract is `msg.sender`.
    /// - We cannot restrict who what kind of account calls this function, including EOAs. However, an integration has
    /// no access to the protocol until {registerIntegrationWithCube3} is called by the integration's admin, for
    /// which a registrarSignature is required and must be signed by the integration's signing authority provided by
    /// CUBE3.
    /// - Only a contract account who initiated registration can complete registration via codesize check.
    ///
    /// Requirements:
    /// - The `initialAdmin` cannot be the zero address.
    /// - The integration, as the `msg.sender`, must not have previously registered with the protocol.
    ///
    /// @param initialAdmin The account to assign admin privileges to for the integration contract.
    ///
    /// @return The PRE_REGISTRATION_SUCCEEDED hash, a unique representation of a successful pre-registration.
    function initiateIntegrationRegistration(address initialAdmin) external returns (bytes32);

    /// @notice Completes the registration of a new integration contract with the CUBE3 protocol. Registered
    /// integrations can have function-protection enabled and thus access the functionality provided by the
    /// Protocol's security modules.
    ///
    /// @dev Emits {UsedRegistrationSignatureHash} and {IntegrationRegistrationStatusUpdated} events.
    ///
    /// Notes:
    /// - Passing an empty array for `enabledByDefaultFnSelectors` will leave all of the integration's functions
    /// protection status disabled by default.
    ///
    /// Requirements:
    /// - `msg.sender` must be the integration's admin account.
    /// - The `integration` cannot be the zero address.
    /// - The `integration` address must belong to a smart contract.
    /// - The `integration` must be pre-registered and have a status of PENDING.
    /// - The `registrarSignature` must not have been used before.
    /// - The `registrarSignature` must be signed by the integration's signing authority provided by CUBE3.
    /// - The CUBE3 Registry must be set on the Router.
    /// - The `integration` must have a valid signing authority account managed by CUBE3.
    /// - The `registrarSignature` must be valid and signed by the integration's signing authority.
    ///
    /// @param integration The address of the integration contract to complete the registration for.
    /// @param registrarSignature The ECDSA registration signature provided by CUBE3, signed by the `integration`
    /// signing authority.
    /// @param enabledByDefaultFnSelectors An array of function selectors to enable function protection for by default.
    function registerIntegrationWithCube3(
        address integration,
        bytes calldata registrarSignature,
        bytes4[] calldata enabledByDefaultFnSelectors
    )
        external;

    /// @notice Updates the registration status of multiple integration contracts in a single call.
    ///
    /// @dev Emits an {IntegrationRegistrationStatusUpdated} event for each update.
    ///
    /// Notes:
    /// - Primarily used to revoke the registration status of multiple integrations in a single call, but
    /// can be used to reset the status to PENDING, or reverse a recovation.
    ///
    /// Requirements:
    /// - `msg.sender` must be a CUBE3 account possessing the CUBE3_INTEGRATION_MANAGER_ROLE role.
    /// - The length of the `integrations` and `statuses` arrays must be the same.
    /// - None of the addresses in the `integrations` array can be the zero address.
    /// - None of the registration status updates can be the same as the current status of the given integration.
    ///
    /// @param integrations An array of integration contract addresses to update the registration status for.
    /// @param statuses An array of registration status statuses to set for the given integrations.
    function batchUpdateIntegrationRegistrationStatus(
        address[] calldata integrations,
        Structs.RegistrationStatusEnum[] calldata statuses
    )
        external;

    /// @notice Updates the registration status of a single integration.
    ///
    /// @dev Emits an {IntegrationRegistrationStatusUpdated} event.
    ///
    /// Notes:
    /// - Primarily used to revoke the registration status of a single integration, but
    /// can be used to reset the status to PENDING, or reverse a recovation.
    ///
    /// Requirements:
    /// - `msg.sender` must be a CUBE3 account possessing the CUBE3_INTEGRATION_MANAGER_ROLE role.
    /// - The `integration` provided cannot be the zero address.
    /// - The updated status cannot be the same as the existing status.
    ///
    /// @param integration The integration contract addresses to update the registration status for.
    /// @param registrationStatus The updated registration status for the `integration`.
    function updateIntegrationRegistrationStatus(
        address integration,
        Structs.RegistrationStatusEnum registrationStatus
    )
        external;

    /// @notice Fetches the signing authority for the given integration.
    /// @dev Will return the zero address for both if the Registry is not set.
    /// @param integration The address of the integration contract to retrieve the signing authority for.
    /// @return registry The Registry where the signing authority was retrieved from
    /// @return authority The signing authority that was retrieved.
    function fetchRegistryAndSigningAuthorityForIntegration(address integration)
        external
        view
        returns (address registry, address authority);


}