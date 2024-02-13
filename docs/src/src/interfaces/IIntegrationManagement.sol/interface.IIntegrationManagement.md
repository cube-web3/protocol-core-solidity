# IIntegrationManagement
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/interfaces/IIntegrationManagement.sol)

Contains the logic for managing the integration contracts that are registered with the CUBE3 protocol.


## Functions
### transferIntegrationAdmin

Begins the 2 step transfer process of the admin account for an integration contract.

*Emits an {IntegrationAdminTransferStarted} event.
Notes:
- No need check for the null address being passed in as the `newAdmin`, as there's no way for the null
address to call this function and complete the transfer.  Setting the integration to the null address in
essence cancels the pending transfer.
Requirements:
- The caller must be the current admin of the integration contract.
- The `newAdmin` must call {acceptIntegrationAdmin} to complete the transfer of privileges.*


```solidity
function transferIntegrationAdmin(address integration, address newAdmin) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract the admin accounts belong to.|
|`newAdmin`|`address`|The account to transfer the admin role to.|


### acceptIntegrationAdmin

Accepts the admin rights for an integration contract and completes the 2 step transfer process.

*Emits {IntegrationAdminTransferred} and {IntegrationPendingAdminRemoved} events.
Requirements:
- The caller must be the `pendingAdmin` set in the {transferIntegrationAdmin} function.*


```solidity
function acceptIntegrationAdmin(address integration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract the admin accounts belong to.|


### updateFunctionProtectionStatus

Updates the protection status of the functions included in the `updates` array for the
specified `integration`.

*Emits an {FunctionProtectionStatusUpdated} event for each update.
Notes:
- Only an integration that has completed the pre-registration process will have an assigned admin
account, during which process the registration status is set to PENDING. Thus, there is no need to
perform a check against integrations with an UNREGISTERED status.
- An integration that has had its registration status set to REVOKED no longer has permission to
enable function protection and can only disable protection for existing functions.
- There is no guardrail against enabling protection using a selector that does not match a function signature
on the `integration` contract.
Requirements:
- Protection for a function can only be enabled if the integration has a REGISTERED status.
- Can only be called by the integration's admin account.*


```solidity
function updateFunctionProtectionStatus(
    address integration,
    Structs.FunctionProtectionStatusUpdate[] calldata updates
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to update the function protection status for.|
|`updates`|`Structs.FunctionProtectionStatusUpdate[]`|Array of {Structs.FunctionProtectionStatusUpdate} structs which pairs the targeted function's selector with the desired protection status.|


### initiateIntegrationRegistration

Initiates the registration of a new integration contract with the CUBE3 protocol.

*Emits {IntegrationAdminTransferred} and {IntegrationRegistrationStatusUpdated} events.
Notes:
- Called by integration contract from inside its constructor, thus the integration contract is `msg.sender`.
- We cannot restrict who what kind of account calls this function, including EOAs. However, an integration has
no access to the protocol until {registerIntegrationWithCube3} is called by the integration's admin, for
which a registrarSignature is required and must be signed by the integration's signing authority provided by
CUBE3.
- Only a contract account who initiated registration can complete registration via codesize check.
Requirements:
- The `initialAdmin` cannot be the zero address.
- The integration, as the `msg.sender`, must not have previously registered with the protocol.*


```solidity
function initiateIntegrationRegistration(address initialAdmin) external returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`initialAdmin`|`address`|The account to assign admin privileges to for the integration contract.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The PRE_REGISTRATION_SUCCEEDED hash, a unique representation of a successful pre-registration.|


### registerIntegrationWithCube3

Completes the registration of a new integration contract with the CUBE3 protocol. Registered
integrations can have function-protection enabled and thus access the functionality provided by the
Protocol's security modules.

*Emits {UsedRegistrationSignatureHash} and {IntegrationRegistrationStatusUpdated} events.
Notes:
- Passing an empty array for `enabledByDefaultFnSelectors` will leave all of the integration's functions
protection status disabled by default.
Requirements:
- `msg.sender` must be the integration's admin account.
- The `integration` cannot be the zero address.
- The `integration` address must belong to a smart contract.
- The `integration` must be pre-registered and have a status of PENDING.
- The `registrarSignature` must not have been used before.
- The `registrarSignature` must be signed by the integration's signing authority provided by CUBE3.
- The CUBE3 Registry must be set on the Router.
- The `integration` must have a valid signing authority account managed by CUBE3.
- The `registrarSignature` must be valid and signed by the integration's signing authority.*


```solidity
function registerIntegrationWithCube3(
    address integration,
    bytes calldata registrarSignature,
    bytes4[] calldata enabledByDefaultFnSelectors
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to complete the registration for.|
|`registrarSignature`|`bytes`|The ECDSA registration signature provided by CUBE3, signed by the `integration` signing authority.|
|`enabledByDefaultFnSelectors`|`bytes4[]`|An array of function selectors to enable function protection for by default.|


### batchUpdateIntegrationRegistrationStatus

Updates the registration status of multiple integration contracts in a single call.

*Emits an {IntegrationRegistrationStatusUpdated} event for each update.
Notes:
- Primarily used to revoke the registration status of multiple integrations in a single call, but
can be used to reset the status to PENDING, or reverse a recovation.
Requirements:
- `msg.sender` must be a CUBE3 account possessing the CUBE3_INTEGRATION_MANAGER_ROLE role.
- The length of the `integrations` and `statuses` arrays must be the same.
- None of the addresses in the `integrations` array can be the zero address.
- None of the registration status updates can be the same as the current status of the given integration.*


```solidity
function batchUpdateIntegrationRegistrationStatus(
    address[] calldata integrations,
    Structs.RegistrationStatusEnum[] calldata statuses
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrations`|`address[]`|An array of integration contract addresses to update the registration status for.|
|`statuses`|`Structs.RegistrationStatusEnum[]`|An array of registration status statuses to set for the given integrations.|


### updateIntegrationRegistrationStatus

Updates the registration status of a single integration.

*Emits an {IntegrationRegistrationStatusUpdated} event.
Notes:
- Primarily used to revoke the registration status of a single integration, but
can be used to reset the status to PENDING, or reverse a recovation.
Requirements:
- `msg.sender` must be a CUBE3 account possessing the CUBE3_INTEGRATION_MANAGER_ROLE role.
- The `integration` provided cannot be the zero address.
- The updated status cannot be the same as the existing status.*


```solidity
function updateIntegrationRegistrationStatus(
    address integration,
    Structs.RegistrationStatusEnum registrationStatus
)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration contract addresses to update the registration status for.|
|`registrationStatus`|`Structs.RegistrationStatusEnum`|The updated registration status for the `integration`.|


### fetchRegistryAndSigningAuthorityForIntegration

Fetches the signing authority for the given integration.

*Will return the zero address for both if the Registry is not set.*


```solidity
function fetchRegistryAndSigningAuthorityForIntegration(address integration)
    external
    view
    returns (address registry, address authority);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to retrieve the signing authority for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The Registry where the signing authority was retrieved from|
|`authority`|`address`|The signing authority that was retrieved.|


