# ProtocolEvents
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/common/ProtocolEvents.sol)

Defines the collective events used throughout the Protocol.


## Events
### RouterModuleInstalled
Emitted when a CUBE3 admin installs a new module.


```solidity
event RouterModuleInstalled(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes32`|The module's computed ID.|
|`moduleAddress`|`address`|The contract address of the module.|
|`version`|`string`|A string representing the modules version in the form `<module_name>-<semantic_version>`.|

### RouterModuleDeprecated
Emitted when a Cube3 admin deprecates an installed module.


```solidity
event RouterModuleDeprecated(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes32`|The computed ID of the module that was deprecated.|
|`moduleAddress`|`address`|The contract address of the module that was deprecated.|
|`version`|`string`|The human-readable version of the deprecated module.|

### RouterModuleRemoved
Emitted when a module is removed from the Router's storage.

*Emitted during the uninstallation of a module.*


```solidity
event RouterModuleRemoved(bytes16 indexed moduleId);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The computed ID of the module being installed.|

### UsedRegistrationSignatureHash
Emitted when committing a used registration signature hash to storage.


```solidity
event UsedRegistrationSignatureHash(bytes32 indexed signatureHash);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signatureHash`|`bytes32`|The keccak256 hash of the ECDSA signature.|

### IntegrationRegistrationStatusUpdated
Emitted when the registration status of an integration is updated.

*Provides an audit trail for changes in the registration status of integrations, enhancing the protocol's
governance transparency.*


```solidity
event IntegrationRegistrationStatusUpdated(address indexed integration, Structs.RegistrationStatusEnum status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract.|
|`status`|`Structs.RegistrationStatusEnum`|The new registration status, represented as an enum.|

### IntegrationAdminUpdated
Emitted when the admin address of an integration is updated.


```solidity
event IntegrationAdminUpdated(address indexed integration, address indexed admin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract whose admin is being updated.|
|`admin`|`address`|The new admin address for the integration.|

### IntegrationPendingAdminRemoved
Emitted when a pending admin for an integration is removed.

*Indicates the successful transfer of the admin account.*


```solidity
event IntegrationPendingAdminRemoved(address indexed integration, address indexed pendingAdmin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract.|
|`pendingAdmin`|`address`|The address of the pending admin being removed.|

### IntegrationAdminTransferStarted
Emitted at the start of an admin transfer for an integration, signaling the initiation of admin change.


```solidity
event IntegrationAdminTransferStarted(
    address indexed integration, address indexed oldAdmin, address indexed pendingAdmin
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract undergoing admin transfer.|
|`oldAdmin`|`address`|The current admin address before the transfer.|
|`pendingAdmin`|`address`|The address of the pending admin set to receive admin privileges.|

### IntegrationAdminTransferred
Emitted when the admin transfer for an integration is completed.


```solidity
event IntegrationAdminTransferred(address indexed integration, address indexed oldAdmin, address indexed newAdmin);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration.|
|`oldAdmin`|`address`|The previous admin address before the transfer.|
|`newAdmin`|`address`|The new admin address after the transfer.|

### FunctionProtectionStatusUpdated
Emitted when the protection status of a function in an integration is updated.

*This event logs changes to whether or not the Protocol is utilized for calls to the designated function.*


```solidity
event FunctionProtectionStatusUpdated(address indexed integration, bytes4 indexed selector, bool status);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract.|
|`selector`|`bytes4`|The function selector (first 4 bytes of the keccak256 hash of the function signature) whose protection status is updated.|
|`status`|`bool`|The new protection status; `true` for protected and `false` for unprotected.|

### ProtocolConfigUpdated
Emitted when protocol-wide configuration settings are updated.


```solidity
event ProtocolConfigUpdated(address indexed registry, bool paused);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The address of the protocol registry contract where configurations are updated.|
|`paused`|`bool`|A boolean indicating the new paused state of the protocol; `true` for paused and `false` for unpaused.|

### ProtocolRegistryRemoved
Emitted when the protocol registry is removed, indicating a significant protocol-wide operation,
possibly for upgrades or migration.

*Until a new protocol is set, new integration registrations will be blocked.*


```solidity
event ProtocolRegistryRemoved();
```

### ProtocolPausedStateChange
Emitted when the protocol is paused


```solidity
event ProtocolPausedStateChange(bool isPaused);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isPaused`|`bool`|A boolean indicating the new paused state of the protocol; `true` for paused and `false` for not.|

### SigningAuthorityUpdated
Emitted when a new signing authority is set.


```solidity
event SigningAuthorityUpdated(address indexed integration, address indexed signer);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration contract's address.|
|`signer`|`address`|The signing authority's account address.|

### SigningAuthorityRevoked
Emitted when a signing authority is revoked.


```solidity
event SigningAuthorityRevoked(address indexed integration, address indexed revokedSigner);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration contract's address.|
|`revokedSigner`|`address`|The signing authority's account address.|

