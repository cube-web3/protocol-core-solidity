# IRouterStorage
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/interfaces/IRouterStorage.sol)

Contains the dedicated getter functions for accessing the Router's storage.


## Functions
### getIsIntegrationFunctionProtected

Gets the protection status of an integration contract's function using the selector.


```solidity
function getIsIntegrationFunctionProtected(address integration, bytes4 fnSelector) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to check the function protection status for.|
|`fnSelector`|`bytes4`|The function selector to check the protection status for.|


### getIntegrationStatus

Gets the registration status of the integration provided.


```solidity
function getIntegrationStatus(address integration) external view returns (Structs.RegistrationStatusEnum);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to check the registration status for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Structs.RegistrationStatusEnum`|The registration status of the integration.|


### getIntegrationPendingAdmin

Gets the pending admin account for the `integration` provided.


```solidity
function getIntegrationPendingAdmin(address integration) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to check the pending admin for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The pending admin account for the integration.|


### getIntegrationAdmin

Gets the admin account for the `integration` provided.


```solidity
function getIntegrationAdmin(address integration) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to retrieve the admin for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The admin account for the integration.|


### getIsProtocolPaused

Gets whether the protocol is paused.


```solidity
function getIsProtocolPaused() external view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the protocol is paused.|


### getModuleAddressById

Gets the contract address of a module using its computed Id.


```solidity
function getModuleAddressById(bytes16 moduleId) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The module's ID derived from the hash of the module's version string.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The module contract's address.|


### getRegistrarSignatureHashExists

Returns whether or not the given signature hash has been used before.


```solidity
function getRegistrarSignatureHashExists(bytes32 signatureHash) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signatureHash`|`bytes32`|The hash of the signature to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the signature hash has been used before.|


### getProtocolConfig

Gets the current protocol configuration.


```solidity
function getProtocolConfig() external view returns (Structs.ProtocolConfig memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`Structs.ProtocolConfig`|The current protocol configuration object containing the registry address and paused state.|


### getRegistryAddress

Gets the contract address of the CUBE3 Registry.


```solidity
function getRegistryAddress() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The contract address of the CUBE3 Registry.|


### getIsModuleVersionDeprecated

Returns whether or not the given module has been deprecated.


```solidity
function getIsModuleVersionDeprecated(bytes16 moduleId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The module's ID derived from the hash of the module's version string.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the module has been deprecated.|


