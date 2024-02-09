# ProtocolEvents
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/common/ProtocolEvents.sol)


## Events
### IntegrationRegistrationRevocationStatusUpdated
Emitted when an integration's revocation status is updated.

*Recovation status will be {True} when the integration is revoked and {False} when the revocation is cleared*


```solidity
event IntegrationRegistrationRevocationStatusUpdated(address indexed integration, bool isRevoked);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration contract whose revocation status is updated.|
|`isRevoked`|`bool`|Whether the `integration` contract is revoked.|

### RouterModuleInstalled
Emitted when a Cube3 admin installs a new module.


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

### Cube3ProtocolContractsUpdated

```solidity
event Cube3ProtocolContractsUpdated(address indexed gateKeeper, address indexed registry);
```

### UsedRegistrationSignatureHash

```solidity
event UsedRegistrationSignatureHash(bytes32 indexed hash);
```

### IntegrationRegistrationStatusUpdated

```solidity
event IntegrationRegistrationStatusUpdated(address indexed integration, Structs.RegistrationStatusEnum status);
```

### IntegrationAdminUpdated

```solidity
event IntegrationAdminUpdated(address indexed integration, address indexed admin);
```

### IntegrationPendingAdminRemoved

```solidity
event IntegrationPendingAdminRemoved(address indexed integration, address indexed pendingAdmin);
```

### IntegrationAdminTransferStarted

```solidity
event IntegrationAdminTransferStarted(
    address indexed integration, address indexed oldAdmin, address indexed pendingAdmin
);
```

### IntegrationAdminTransferred

```solidity
event IntegrationAdminTransferred(address indexed integration, address indexed oldAdmin, address indexed newAdmin);
```

### FunctionProtectionStatusUpdated

```solidity
event FunctionProtectionStatusUpdated(address indexed integration, bytes4 indexed selector, bool status);
```

### ProtocolConfigUpdated

```solidity
event ProtocolConfigUpdated(address indexed registry, bool paused);
```

### ProtocolRegistryRemoved

```solidity
event ProtocolRegistryRemoved();
```

### InitiateReg

```solidity
event InitiateReg(address integration, Structs.IntegrationState state);
```

### LogModuleSelector

```solidity
event LogModuleSelector(bytes4 s);
```

### LogModuleId

```solidity
event LogModuleId(bytes32 id);
```

### LogPayload

```solidity
event LogPayload(bytes b);
```

### LogDataHash

```solidity
event LogDataHash(bytes32 h);
```

### LogInt

```solidity
event LogInt(uint256 u);
```

### LogDigsest

```solidity
event LogDigsest(bytes32 d);
```

### LogMsgData

```solidity
event LogMsgData(bytes m);
```

