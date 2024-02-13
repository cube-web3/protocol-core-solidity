# ICube3SecurityModule
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/interfaces/ICube3SecurityModule.sol)

Provides an interface for the functionality shared by all CUBE3 Security Modules.
Notes:
- All CUBE3 security modules will inherit this base contract.
- This contract is used through inheritance only.
- Any module that inherits this contract should never make use of `selfdestruct` or
delegatecall to a contract that might, as it could potentially render the router proxy
inoperable.


## Functions
### deprecate

Deprecates the module so that it cannot be used or reinstalled.

*Emits a [ModuleDeprecated](/src/interfaces/ICube3SecurityModule.sol/interface.ICube3SecurityModule.md#moduledeprecated) event.
Notes:
- Can be overridden in the event additional logic needs to be executed during deprecation. The overriding
function MUST use `onlyCube3Router` modifier to ensure access control mechanisms are applied.
Once a module has been deprecated it cannot be reinstalled in the router.
Requirements:
- `msg.sender` is the CUBE3 Router contract.*


```solidity
function deprecate() external returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version string of the module.|


### moduleVersion

The human-readable version of the module.

*Module version scheme is as follows: `<module_name>-<semantic_version>`, eg. `signature-0.0.1`
Validation of the moduleVersion string must be done by the deployer*


```solidity
function moduleVersion() external view returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The module version as a string|


### isDeprecated

Indicates whether the module has been deprecated.


```solidity
function isDeprecated() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|The deprecation status of the module|


### moduleId

Gets the ID of the module.

*Computes the keccak256 hash of the abi.encoded moduleVersion in storage.*


```solidity
function moduleId() external view returns (bytes16);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes16`|The module's computed ID.|


### supportsInterface

Checks if the contract implements an interface.


```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interface identifier, as specified in ERC-165.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool `true` if the contract implements `interfaceId`, `false` otherwise.|


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

