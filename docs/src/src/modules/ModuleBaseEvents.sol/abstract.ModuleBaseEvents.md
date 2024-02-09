# ModuleBaseEvents
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/modules/ModuleBaseEvents.sol)


## Events
### ModuleDeployed
Emitted when a new Cube Module is deployed.


```solidity
event ModuleDeployed(address indexed routerAddress, bytes32 indexed moduleId, string indexed version);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`routerAddress`|`address`|The address of the Cube3RouterProxy.|
|`moduleId`|`bytes32`|The computed ID of the module.|
|`version`|`string`|The human-readble module version.|

### ModuleDeprecated
Emitted when the module is deprecated.


```solidity
event ModuleDeprecated(bytes32 indexed moduleId, string indexed version);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes32`|The computed ID of the module.|
|`version`|`string`| The human-readable module version.|

