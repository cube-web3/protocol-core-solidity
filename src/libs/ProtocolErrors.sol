// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title CUBE3 Protocol Errors
/// @notice Defines errors for the CUBE3 Protocol.

library ProtocolErrors {
    /////////////////////////////////////////////////////////////////////////////////
    //                               Shared Protocol                               //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the target address is not an EOA or a contract under construction.
    error Cube3Protocol_TargetNotAContract(address target);

    /// @notice Throws when the target address is a contract.
    error Cube3Protocol_TargetIsContract(address target);

    /// @notice Throws when the arrays passed as arguments are not the same length.
    error Cube3Protocol_ArrayLengthMismatch();

    /// @notice Throws when the integration address provided is the zero address.
    error Cube3Protocol_InvalidIntegration();

    /////////////////////////////////////////////////////////////////////////////////
    //                                   Router                                    //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the provided registry address is the Zero address.
    error Cube3Router_InvalidRegistry();

    /// @notice Throws when the module address being retrieved using the ID doesn't exist.
    error Cube3Router_ModuleNotInstalled(bytes16 moduleId);

    /// @notice Throws when the module returns data that doesn't match the expected MODULE_CALL_SUCCEEDED hash.
    error Cube3Router_ModuleReturnedInvalidData();

    /// @notice Throws when the data returned by the module is not 32 bytes in length.
    error Cube3Router_ModuleReturnDataInvalidLength(uint256 size);

    /// @notice Throws when an integration attempts to register when the protocol is paused.
    error Cube3Router_ProtocolPaused();

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

    /// @notice Throws when attempting to use a registrar signature that has already been used to register
    /// an integration.
    error Cube3Router_RegistrarSignatureAlreadyUsed();

    /// @notice Throws when the registry contract is not set.
    error Cube3Router_RegistryNotSet();

    /// @notice Throws when the integration's signing authority has not been set, ie returns the Zero Address.
    error Cube3Router_IntegrationSigningAuthorityNotSet();

    /// @notice Throws when setting the registration status to its current status.
    error Cube3Router_CannotSetStatusToCurrentStatus();

    /// @notice Throws when attempting to set function protection status for the 0x00000000 selector.
    error Cube3Router_InvalidFunctionSelector();

    /////////////////////////////////////////////////////////////////////////////////
    //                         Router : ProtocolManagement                         //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the contract at the address provided does not support the CUBE3 Registry interface.
    error Cube3Router_NotValidRegistryInterface();

    /// @notice Throws when the zero address is provided when installing a module.
    error Cube3Router_InvalidAddressForModule();

    /// @notice Throws when empty bytes are provided for the ID when installing a module.
    error Cube3Router_InvalidIdForModule();

    /// @notice Throws when the module being installed is does not support the interface.
    error Cube3Router_ModuleInterfaceNotSupported();

    /// @notice Throws when the module ID provided is already installed.
    error Cube3Router_ModuleAlreadyInstalled();

    /// @notice Throws when the module ID does not match the hashed version.
    error Cube3Router_ModuleVersionNotMatchingID();

    /// @notice Throws when the module contract beign installed has been deprecated.
    error Cube3Router_CannotInstallDeprecatedModule();

    /// @notice Throws when deprecating a module fails.
    error Cube3Router_ModuleDeprecationFailed();

    /////////////////////////////////////////////////////////////////////////////////
    //                         Signature Utils                                     //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the signer recoverd from the signature is the zero address.
    error Cube3SignatureUtils_SignerZeroAddress();

    /// @notice Throws when the signer recovered from the message hash does not match the expected signer
    error Cube3SignatureUtils_InvalidSigner();

    /////////////////////////////////////////////////////////////////////////////////
    //                            Generic Module                                   //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the address provided for the Router proxy is the zero address.
    error Cube3Module_InvalidRouter();

    /// @notice Throws when the version string does not match the required schema.
    error Cube3Module_DoesNotConformToVersionSchema();

    /// @notice Throws when attempting to deploy a module with a version that already exists.
    error Cube3Module_ModuleVersionExists();

    /// @notice Throws when the caller is not the CUBE3 Router.
    error Cube3Module_OnlyRouterAsCaller();

    /////////////////////////////////////////////////////////////////////////////////
    //                         Signature Module                                    //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the signing authority and univeral signer are null.
    error Cube3SignatureModule_NullSigningAuthority();

    /// @notice Throws when the expected nonce does not match the user's nonce in storage.
    error Cube3SignatureModule_InvalidNonce();

    /// @notice Throws when the timestamp contained in the module payload is in the past.
    error Cube3SignatureModule_ExpiredSignature();

    /////////////////////////////////////////////////////////////////////////////////
    //                         Registry                                   //
    /////////////////////////////////////////////////////////////////////////////////

    /// @notice Throws when the signing authority address provided is the zero address.
    error Cube3Registry_InvalidSigningAuthority();

    /// @notice Throws when the signing authority retrieved from storage doesn't exist.
    error Cube3Registry_NonExistentSigningAuthority();

    /// @notice Throws when the universal backup signer is the zero address
    error Cube3Registry_NullUniversalSigner();
}
