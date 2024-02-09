# ICube3Module
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/interfaces/ICube3Module.sol)

**Author:**
CUBE3.ai

Provides the module with connectivity to the Cube3Router and manages the module's versioning.

*All CUBE3 security modules will inherit this base contract.*

*This module is used through inheritance.*

*Any module that inherits this contract should never make use of `selfdestruct` or
delegatecall to a contract that might, as it could potentially render the router proxy
inoperable.*


## Functions
### moduleVersion

The human-readable version of the module.

*Module version scheme is as follows: `<module_name>-<semantic_version>`, eg. `signature-0.0.1`*

*Validation of the moduleVersion string must be done by the deployer*


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


### deprecate

Deprecates the module.

*Only callable by the Cube3Router.*

*Deprecation event emitted by the router, see {Cube3RouterLogic-deprecateModule}.*

*Once a module has been deprecated it cannot be reinstalled in the router.*


```solidity
function deprecate() external returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The deprecation status and human-readable module version|


### moduleId

Gets the ID of the module

*computes the keccak256 hash of the abi.encoded moduleVersion*


```solidity
function moduleId() external view returns (bytes16);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes16`|The module's computed ID|

