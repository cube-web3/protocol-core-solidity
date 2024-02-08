// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title CUBE3 Protocol Errors
/// @notice Defines errors for the CUBE3 Protocol.

library ProtocolErrors {

    /////////////////////////////////////////////////////////////////////////////////
    //                                  Shared Protocol                            //
    /////////////////////////////////////////////////////////////////////////////////

   /// @notice Throws when the target address is not an EOA or a contract under construction.
   error Cube3Protocol_TargetNotAContract(address target);

   /// @notice Throws when the target address is a contract.
   error Cube3Protocol_TargetIsContract(address target);

   /// @notice Throws when the arrays passed as arguments are not the same length.
   error Cube3Router_ArrayLengthMismatch();


    /////////////////////////////////////////////////////////////////////////////////
    //                                       Router                                //
    /////////////////////////////////////////////////////////////////////////////////

   /// @notice Throws when the provided registry address is the Zero address. 
   error Cube3Router_InvalidRegistry();

   /// @notice Throws when the module address being retrieved using the ID doesn't exist.
   error Cube3Router_ModuleNotInstalled(bytes16 moduleId);

   /// @notice Throws when the module returns data that doesn't match the expected MODULE_CALL_SUCCEEDED hash.
   error Cube3Router_ModuleReturnedInvalidData();
 
   /// @notice Throws when the data returned by the module is not 32 bytes in length.
   error Cube3Router_ModuleReturnDataInvalidLength(uint256 size);

    /////////////////////////////////////////////////////////////////////////////////
    //                         Router : IntegrationManagement                      //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the caller is not the integration's admin account.
    error Cube3Router_CallerNotIntegrationAdmin();

    /// @notice Throws when the caller is not the integration's pending admin account.
    error Cube3Router_CallerNotPendingIntegrationAdmin();

    /// @notice Throws when the calling integration's status is still PENDING.
    error Cube3Router_IntegrationRegistrationNotComplete();

    /// @notice Throws when the calling integration's registration status is not PENDING.
    error Cube3Router_IntegrationRegistrationStatusNotPending();

    /// @notice Throws when the calling integration's registration status is REVOKED.
    error Cube3Router_IntegrationRegistrationRevoked();

    /// @notice Throws when the integration admin address is the Zero Address.
    error Cube3Router_InvalidIntegrationAdmin();

    /// @notice Throws when the integration admin address has already been set, indicating
    /// that the integration has already been pre-registered.
    error Cube3Router_IntegrationAdminAlreadyInitialized();

    /// @notice Throws when the integration address provided is the zero address.
    error Cube3Router_InvalidIntegration();

    /// @notice Throws when attempting to use a registrar signature that has already been used to register
    /// an integration.
    error Cube3Router_RegistrarSignatureAlreadyUsed();

    /// @notice Throws when the registry contract is not set.
    error Cube3Router_RegistryNotSet();

    /// @notice Throws when the integration's signing authority has not been set, ie returns the Zero Address.
    error Cube3Router_IntegrationSigningAuthorityNotSet();
}