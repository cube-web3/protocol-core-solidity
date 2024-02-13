# RouterStorage
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/abstracts/RouterStorage.sol)

**Inherits:**
[IRouterStorage](/src/interfaces/IRouterStorage.sol/interface.IRouterStorage.md), [ProtocolEvents](/src/common/ProtocolEvents.sol/abstract.ProtocolEvents.md), [ProtocolAdminRoles](/src/common/ProtocolAdminRoles.sol/abstract.ProtocolAdminRoles.md), [ProtocolConstants](/src/common/ProtocolConstants.sol/abstract.ProtocolConstants.md)

The contracts contains all logic for reading and writing to contract storage.

*This contract utilizes namespaced storage layout (ERC-7201). All storage access happens via
the `_state()` function, which returns a storage pointer to the `Cube3State` struct.  Storage variables
can only be accessed via dedicated getter and setter functions.*


## State Variables
### CUBE3_ROUTER_STORAGE_LOCATION

```solidity
bytes32 private constant CUBE3_ROUTER_STORAGE_LOCATION =
    0xd26911dcaedb68473d1e75486a92f0a8e6ef3479c0c1c4d6684d3e2888b6b600;
```


## Functions
### _state


```solidity
function _state() private pure returns (Cube3State storage state);
```

### getIsIntegrationFunctionProtected

Gets the protection status of an integration contract's function using the selector.


```solidity
function getIsIntegrationFunctionProtected(address integration, bytes4 fnSelector) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The address of the integration contract to check the function protection status for.|
|`fnSelector`|`bytes4`|The function selector to check the protection status for.|


### getIntegrationStatus

Gets the registration status of the integration provided.


```solidity
function getIntegrationStatus(address integration) public view returns (Structs.RegistrationStatusEnum);
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
function getIntegrationPendingAdmin(address integration) public view returns (address);
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
function getIntegrationAdmin(address integration) public view returns (address);
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
function getIsProtocolPaused() public view returns (bool);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the protocol is paused.|


### getModuleAddressById

Gets the contract address of a module using its computed Id.


```solidity
function getModuleAddressById(bytes16 moduleId) public view returns (address);
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
function getRegistrarSignatureHashExists(bytes32 signatureHash) public view returns (bool);
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
function getRegistryAddress() public view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The contract address of the CUBE3 Registry.|


### getIsModuleVersionDeprecated

Returns whether or not the given module has been deprecated.


```solidity
function getIsModuleVersionDeprecated(bytes16 moduleId) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The module's ID derived from the hash of the module's version string.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True if the module has been deprecated.|


### _updateProtocolConfig

Updates the protocol configuration in storage with the new registry and paused state.

*If the `registry` is not being changed, the existing address should be passed. Only emits
the {ProtocolRegistryRemoved} event if the registry is being removed and the
{ProtocolPausedStateChange} event if the paused state is being changed.*


```solidity
function _updateProtocolConfig(address registry, bool isPaused) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The new registry address.|
|`isPaused`|`bool`|The new paused state.|


### _setProtocolPausedUnpaused

Pauses or unpauses the protocol.

*Used to pause/unpause the protocol when the registry doesn't need to be updated.*


```solidity
function _setProtocolPausedUnpaused(bool isPaused) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isPaused`|`bool`|The new paused state: 'true' for paused, 'false' for unpaused.|


### _setPendingIntegrationAdmin

Sets the pending admin for an integration in storage.

*Retrieves the current admin from storage to add to the event.*


```solidity
function _setPendingIntegrationAdmin(address integration, address pendingAdmin) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration address to set the pending admin for.|
|`pendingAdmin`|`address`|The new pending admin of the integration.|


### _setIntegrationAdmin

Sets the admin for an integration in storage.


```solidity
function _setIntegrationAdmin(address integration, address newAdmin) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration address to set the admin for.|
|`newAdmin`|`address`|The new admin of the integration.|


### _setFunctionProtectionStatus

Sets the protection status for a function in an integration in storage.


```solidity
function _setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration address to set the protection status for.|
|`fnSelector`|`bytes4`|The function selector belonging to `integration` to set the protection status for.|
|`isEnabled`|`bool`|The new protection status for the function, where `true` means function protection is enabled.|


### _setIntegrationRegistrationStatus

Sets the registration status for an integration in storage.


```solidity
function _setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration address to set the registration status for.|
|`status`|`Structs.RegistrationStatusEnum`|The new registration status for the integration, including the selector and protection status.|


### _setModuleInstalled

Sets the installed module in storage.


```solidity
function _setModuleInstalled(bytes16 moduleId, address moduleAddress, string memory version) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The module ID to set the module for, derived from the abi.encoded hash of the version.|
|`moduleAddress`|`address`|The new module address.|
|`version`|`string`|The version of the module.|


### _setUsedRegistrationSignatureHash

Sets the used registrar signature hash in storage.


```solidity
function _setUsedRegistrationSignatureHash(bytes32 signatureHash) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`signatureHash`|`bytes32`|The keccak256 hash of the ECDSA signature.|


### _setModuleVersionDeprecated

Sets a module as deprecated in storage.


```solidity
function _setModuleVersionDeprecated(bytes16 moduleId, string memory version) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The module ID to set as deprecated.|
|`version`|`string`|The version of the module.|


### _deleteIntegrationPendingAdmin

Removes the pending integration admin from storage.

*Provides a small gas refund.*


```solidity
function _deleteIntegrationPendingAdmin(address integration) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integration`|`address`|The integration address to remove the pending admin for.|


### _deleteInstalledModule

Removes an installed module from storage.

*Invoked when a module is uninstalled. Provides a small gas refund.*


```solidity
function _deleteInstalledModule(bytes16 moduleId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The ID belonging to the module to remove.|


