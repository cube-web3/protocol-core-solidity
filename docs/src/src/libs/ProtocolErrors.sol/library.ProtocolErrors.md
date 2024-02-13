# ProtocolErrors
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/libs/ProtocolErrors.sol)

Defines errors for the CUBE3 Protocol.


## Errors
### Cube3Protocol_TargetNotAContract
Throws when the target address is not an EOA or a contract under construction.


```solidity
error Cube3Protocol_TargetNotAContract(address target);
```

### Cube3Protocol_TargetIsContract
Throws when the target address is a contract.


```solidity
error Cube3Protocol_TargetIsContract(address target);
```

### Cube3Protocol_ArrayLengthMismatch
Throws when the arrays passed as arguments are not the same length.


```solidity
error Cube3Protocol_ArrayLengthMismatch();
```

### Cube3Protocol_InvalidIntegration
Throws when the integration address provided is the zero address.


```solidity
error Cube3Protocol_InvalidIntegration();
```

### Cube3Router_InvalidRegistry
Throws when the provided registry address is the Zero address.


```solidity
error Cube3Router_InvalidRegistry();
```

### Cube3Router_ModuleNotInstalled
Throws when the module address being retrieved using the ID doesn't exist.


```solidity
error Cube3Router_ModuleNotInstalled(bytes16 moduleId);
```

### Cube3Router_ModuleReturnedInvalidData
Throws when the module returns data that doesn't match the expected MODULE_CALL_SUCCEEDED hash.


```solidity
error Cube3Router_ModuleReturnedInvalidData();
```

### Cube3Router_ModuleReturnDataInvalidLength
Throws when the data returned by the module is not 32 bytes in length.


```solidity
error Cube3Router_ModuleReturnDataInvalidLength(uint256 size);
```

### Cube3Router_ProtocolPaused
Throws when an integration attempts to register when the protocol is paused.


```solidity
error Cube3Router_ProtocolPaused();
```

### Cube3Router_CallerNotIntegrationAdmin
Throws when the caller is not the integration's admin account.


```solidity
error Cube3Router_CallerNotIntegrationAdmin();
```

### Cube3Router_CallerNotPendingIntegrationAdmin
Throws when the caller is not the integration's pending admin account.


```solidity
error Cube3Router_CallerNotPendingIntegrationAdmin();
```

### Cube3Router_IntegrationRegistrationNotComplete
Throws when the calling integration's status is still PENDING.


```solidity
error Cube3Router_IntegrationRegistrationNotComplete();
```

### Cube3Router_IntegrationRegistrationStatusNotPending
Throws when the calling integration's registration status is not PENDING.


```solidity
error Cube3Router_IntegrationRegistrationStatusNotPending();
```

### Cube3Router_IntegrationRegistrationRevoked
Throws when the calling integration's registration status is REVOKED.


```solidity
error Cube3Router_IntegrationRegistrationRevoked();
```

### Cube3Router_InvalidIntegrationAdmin
Throws when the integration admin address is the Zero Address.


```solidity
error Cube3Router_InvalidIntegrationAdmin();
```

### Cube3Router_IntegrationAdminAlreadyInitialized
Throws when the integration admin address has already been set, indicating
that the integration has already been pre-registered.


```solidity
error Cube3Router_IntegrationAdminAlreadyInitialized();
```

### Cube3Router_RegistrarSignatureAlreadyUsed
Throws when attempting to use a registrar signature that has already been used to register
an integration.


```solidity
error Cube3Router_RegistrarSignatureAlreadyUsed();
```

### Cube3Router_RegistryNotSet
Throws when the registry contract is not set.


```solidity
error Cube3Router_RegistryNotSet();
```

### Cube3Router_IntegrationSigningAuthorityNotSet
Throws when the integration's signing authority has not been set, ie returns the Zero Address.


```solidity
error Cube3Router_IntegrationSigningAuthorityNotSet();
```

### Cube3Router_CannotSetStatusToCurrentStatus
Throws when setting the registration status to its current status.


```solidity
error Cube3Router_CannotSetStatusToCurrentStatus();
```

### Cube3Router_InvalidFunctionSelector
Throws when attempting to set function protection status for the 0x00000000 selector.


```solidity
error Cube3Router_InvalidFunctionSelector();
```

### Cube3Router_NotValidRegistryInterface
Throws when the contract at the address provided does not support the CUBE3 Registry interface.


```solidity
error Cube3Router_NotValidRegistryInterface();
```

### Cube3Router_InvalidAddressForModule
Throws when the zero address is provided when installing a module.


```solidity
error Cube3Router_InvalidAddressForModule();
```

### Cube3Router_InvalidIdForModule
Throws when empty bytes are provided for the ID when installing a module.


```solidity
error Cube3Router_InvalidIdForModule();
```

### Cube3Router_ModuleInterfaceNotSupported
Throws when the module being installed is does not support the interface.


```solidity
error Cube3Router_ModuleInterfaceNotSupported();
```

### Cube3Router_ModuleAlreadyInstalled
Throws when the module ID provided is already installed.


```solidity
error Cube3Router_ModuleAlreadyInstalled();
```

### Cube3Router_ModuleVersionNotMatchingID
Throws when the module ID does not match the hashed version.


```solidity
error Cube3Router_ModuleVersionNotMatchingID();
```

### Cube3Router_CannotInstallDeprecatedModule
Throws when the module contract beign installed has been deprecated.


```solidity
error Cube3Router_CannotInstallDeprecatedModule();
```

### Cube3Router_ModuleDeprecationFailed
Throws when deprecating a module fails.


```solidity
error Cube3Router_ModuleDeprecationFailed();
```

### Cube3SignatureUtils_SignerZeroAddress
Throws when the signer recoverd from the signature is the zero address.


```solidity
error Cube3SignatureUtils_SignerZeroAddress();
```

### Cube3SignatureUtils_InvalidSigner
Throws when the signer recovered from the message hash does not match the expected signer


```solidity
error Cube3SignatureUtils_InvalidSigner();
```

### Cube3Module_InvalidRouter
Throws when the address provided for the Router proxy is the zero address.


```solidity
error Cube3Module_InvalidRouter();
```

### Cube3Module_DoesNotConformToVersionSchema
Throws when the version string does not match the required schema.


```solidity
error Cube3Module_DoesNotConformToVersionSchema();
```

### Cube3Module_ModuleVersionExists
Throws when attempting to deploy a module with a version that already exists.


```solidity
error Cube3Module_ModuleVersionExists();
```

### Cube3Module_OnlyRouterAsCaller
Throws when the caller is not the CUBE3 Router.


```solidity
error Cube3Module_OnlyRouterAsCaller();
```

### Cube3SignatureModule_NullSigningAuthority
Throws when the signing authority and univeral signer are null.


```solidity
error Cube3SignatureModule_NullSigningAuthority();
```

### Cube3SignatureModule_InvalidNonce
Throws when the expected nonce does not match the user's nonce in storage.


```solidity
error Cube3SignatureModule_InvalidNonce();
```

### Cube3SignatureModule_ExpiredSignature
Throws when the timestamp contained in the module payload is in the past.


```solidity
error Cube3SignatureModule_ExpiredSignature();
```

### Cube3Registry_InvalidSigningAuthority
Throws when the signing authority address provided is the zero address.


```solidity
error Cube3Registry_InvalidSigningAuthority();
```

### Cube3Registry_NonExistentSigningAuthority
Throws when the signing authority retrieved from storage doesn't exist.


```solidity
error Cube3Registry_NonExistentSigningAuthority();
```

### Cube3Registry_NullUniversalSigner
Throws when the universal backup signer is the zero address


```solidity
error Cube3Registry_NullUniversalSigner();
```

