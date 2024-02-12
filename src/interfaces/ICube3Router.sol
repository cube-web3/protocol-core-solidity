// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Structs } from "@src/common/Structs.sol";

/// @title ICube3Router
/// @notice Contains the collective logic for the {Cube3RouterImpl} contract and the contracts it inherits from:
/// {ProtocolManagement}, {IntegrationManagement}, and {RouterStorage}.
/// @dev All events are defined in {ProtocolEvents}.
interface ICube3Router {
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

    /*//////////////////////////////////////////////////////////////////////////
                                Integration Management
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Updates the protocol configuration.
    ///
    /// @dev Emits {ProtocolConfigUpdated} and conditionally {ProtocolRegistryRemoved} events
    ///
    /// Notes:
    /// - We allow the registry to be set to the zero address in the event of a compromised KMS. This will
    /// prevent any new integrations from being registered until the Registry contract is replaced.
    /// - Allows a Protocol Admin to update the Registry and pause the protocol.
    /// - Pausing the protocol prevents new registrations and will force all calls to {Cube3RouterImpl-routeToModule}
    /// to return early.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.
    /// - If not the zero address, the smart contract at `registry` must support the ICube3Registry interface.
    ///
    /// @param registry The address of the Cube3Registry contract.
    /// @param isPaused Whether the protocol is paused or not.
    function updateProtocolConfig(address registry, bool isPaused) external;

    /// @notice Calls a function using the calldata provided on the given module.
    ///
    /// @dev Emits any events emitted by the module function being called.
    ///
    /// Notes:
    /// - Used to call privileged functions on modules where only the router has access.
    /// - Acts similar to a proxy, except uses `call` instead of `delegatecall`.
    /// - The module address is retrived from storage using the `moduleId`.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.
    /// - The module represented by `moduleId` must be installed.
    ///
    /// @param moduleId The ID of the module to call the function on.
    /// @param fnCalldata The calldata for the function to call on the module.
    ///
    /// @return The return or revert data from the module function call.
    function callModuleFunctionAsAdmin(bytes16 moduleId, bytes calldata fnCalldata) external returns (bytes memory);

    /// @notice Adds a new module to the Protocol.
    ///
    /// @dev Emits an {RouterModuleInstalled} event.
    ///
    /// Notes:
    /// - Module IDs are included in the routing bitmap at the tail of the `cube3Payload` and
    /// and are used to dynamically retrieve the contract address for the destination module from storage.
    /// - The Router can only make calls to modules registered via this function.
    /// - Can only install module contracts that have been deployed and support the {ICube3Module} interface.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE role.
    /// - The `moduleAddress` cannot be the zero address.
    /// - The `moduleAddress` must be a smart contract that supports the ICube3Module interface.
    /// - The `moduleId` must not contain empty bytes or have been installed before.
    /// - The `moduleId` provided must match the hash of the version string stored in the module contract.
    /// - The module must not have previously been deprecated.
    ///
    /// @param moduleAddress The contract address where the module is located.
    /// @param moduleId The corresponding module ID generated from the hash of its version string.
    function installModule(address moduleAddress, bytes16 moduleId) external;

    /// @notice Deprecates an installed module.
    ///
    /// @dev Emits {RouterModuleDeprecated} and {RouterModuleRemoved} events.
    ///
    /// Notes:
    /// - Deprecation removes the `moduleId` from the list of active modules and adds its to a list
    /// of deprecated modules that ensures it cannot be re-installed.
    /// - If a module is accidentally deprecated, it can be re-installed with a new version string.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE role.
    /// - The module must currently be installed.
    /// - The call to the {deprecate} function on the module must succeed.
    ///
    /// @param moduleId The module ID of the module to deprecate.
    function deprecateModule(bytes16 moduleId) external;

    /*//////////////////////////////////////////////////////////////////////////
                                Router Storage
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Gets the protection status of an integration contract's function using the selector.
    /// @param integration The address of the integration contract to check the function protection status for.
    /// @param fnSelector The function selector to check the protection status for.
    function getIsIntegrationFunctionProtected(address integration, bytes4 fnSelector) external view returns (bool);

    /// @notice Gets the registration status of the integration provided.
    /// @param integration The address of the integration contract to check the registration status for.
    /// @return The registration status of the integration.
    function getIntegrationStatus(address integration) external view returns (Structs.RegistrationStatusEnum);

    /// @notice Gets the pending admin account for the `integration` provided.
    /// @param integration The address of the integration contract to check the pending admin for.
    /// @return The pending admin account for the integration.
    function getIntegrationPendingAdmin(address integration) external view returns (address);

    /// @notice Gets the admin account for the `integration` provided.
    /// @param integration The address of the integration contract to retrieve the admin for.
    /// @return The admin account for the integration.
    function getIntegrationAdmin(address integration) external view returns (address);

    /// @notice Gets whether the protocol is paused.
    /// @return True if the protocol is paused.
    function getIsProtocolPaused() external view returns (bool);

    /// @notice Gets the contract address of a module using its computed Id.
    /// @param moduleId The module's ID derived from the hash of the module's version string.
    /// @return The module contract's address.
    function getModuleAddressById(bytes16 moduleId) external view returns (address);

    /// @notice Returns whether or not the given signature hash has been used before.
    /// @param signatureHash The hash of the signature to check.
    /// @return True if the signature hash has been used before.
    function getRegistrarSignatureHashExists(bytes32 signatureHash) external view returns (bool);

    /// @notice Gets the current protocol configuration.
    /// @return The current protocol configuration object containing the registry address and paused state.
    function getProtocolConfig() external view returns (Structs.ProtocolConfig memory);

    /// @notice Gets the contract address of the CUBE3 Registry.
    /// @return The contract address of the CUBE3 Registry.
    function getRegistryAddress() external view returns (address);

    /// @notice Returns whether or not the given module has been deprecated.
    /// @param moduleId The module's ID derived from the hash of the module's version string.
    /// @return True if the module has been deprecated.
    function getIsModuleVersionDeprecated(bytes16 moduleId) external view returns (bool);

    /// @notice Initializes the proxy's implementation contract.
    /// @dev Can only be called during the proxy's construction.
    /// @dev Omits any argument to avoid changing deployment bytecode across EVM chains.
    /// @dev See {Cube3RouterProxy-construcot} constructor for implementation details.
    function initialize() external;

    /// @notice Routes transactions from any Cube3Integration integration to a designated CUBE3 module.
    /// @dev Can only be called by integration contracts that have registered with the router.
    /// @dev A successful module function's execution should always return TRUE.
    /// @dev A failed module function's execution, or not meeting the conditions layed out in the module, should always
    /// revert.
    /// @dev Makes a low-level call to the module that includes all relevent data.
    /// @param integrationMsgSender The msgSender of the originating Cube3Integration function.
    /// @param integrationSelf The Cube3Integration integration contract address, passes by itself as the _self ref.
    /// @param integrationMsgValue The msg.value of the originating Cube3Integration function call.
    /// @param integrationMsgValue The msg.value of the originating Cube3Integration function call.
    /// @param cube3PayloadLength The length of the CUBE3 payload.
    /// @return Whether the module's function execution was successful.
    function routeToModule(
        address integrationMsgSender,
        address integrationSelf,
        uint256 integrationMsgValue,
        uint256 cube3PayloadLength,
        bytes calldata integrationMsgData
    )
        external
        returns (bool);

    /// @notice Registers the calling contract's address as an integration.
    /// @dev Cannot be called by a contract's constructor as the `supportsInterface` callback would fail.
    /// @dev Can only be called by a contract, EOAS are prevented from calling via {supportsInterface} callback.
    /// @dev There is no guarantee the calling contract is a legitimate Cube3Integration contract.
    /// @dev The registrarSignature needs to be attained from the CUBE3 service.
    /// @dev msg.sender will be the proxy contract, not the implementation, if it is a proxy registering.
    /// @dev Unauthorized contracts can be revoked manually by an admin, see {setIntegrationAuthorizationStatus}.
    /// @param integrationSelf The contract address of the integration contract being registered.
    /// @param registrarSignature The registration signature provided by the integration's signing authority.
    function initiate2StepIntegrationRegistration(
        address integrationSelf,
        bytes calldata registrarSignature
    )
        external
        returns (bool success);

    /// @notice Manually sets/updates the designated integration contract's registration status.
    /// @dev Can only be called by a CUBE3 admin.
    /// @dev Can be used to reset an upgradeable proxy implementation's registration status.
    /// @dev If the integration is a standalone contract (not using a proxy), the `integrationOrProxy` and
    ///      `integrationOrImplementation` parameters will be the same address.
    /// @param integrationOrProxy The contract address of the integration contract (or its proxy).
    /// @param integrationOrImplementation The contract address of the integration's implementation contract (or itself
    /// if not a proxy).
    /// @param registrationStatus The registration status status to set.
    function setIntegrationRegistrationStatus(
        address integrationOrProxy,
        address integrationOrImplementation,
        Structs.RegistrationStatusEnum registrationStatus
    )
        external;

    /// @notice Sets the CUBE3 protocol contract addresses.
    /// @dev Performs checks using {supportsInterface} to ensure the correct addresses are passed in.
    /// @dev We cannot pass in the addresses during intialization, as we need the deployed bytecode to be the same
    ///      on all EVM chains for use with the constant address deployer proxy.
    /// @dev MUST be called immediately after deployment, before any other functions are called.
    /// @param cube3GateKeeper The address of the Cube3GateKeeper contract.
    /// @param cube3RegistryProxy The address of the Cube3Registry proxy contract.
    function setProtocolContracts(address cube3GateKeeper, address cube3RegistryProxy) external;

    /// @notice Gets the contract address of a module using its computed ID.
    /// @dev `moduleId` is computed from keccak256(abi.encode(versionString)).
    /// @param moduleId The module's ID derived from the hash of the module's version string.
    /// @return The module contract's address.
    function getModuleAddressById(bytes16 moduleId) external view returns (address);

    /// @notice Whether the supplied contract is both a registered integration and has a protection status of ACTIVE.
    /// @param integrationOrProxy The contract address of the integration (or its proxy) contract being queried.
    /// @param integrationOrImplementation The contract address of the integration's implementation contract.
    /// @return Whether the provided integration is actively protected.
    function isProtectedIntegration(
        address integrationOrProxy,
        address integrationOrImplementation
    )
        external
        view
        returns (bool);

    /// @notice Get the current proxy implementation's address.
    /// @dev Will return the address of the Cube3RouterProxy's current implementation/logic contract.
    /// @dev Conforms to the UUPS spec.
    /// @return The contract address of this active implementation contract.
    function getImplementation() external view returns (address);

    function getIntegrationAdmin(address integration) external view returns (address);

    function getRegistryAddress() external view returns (address);
}
