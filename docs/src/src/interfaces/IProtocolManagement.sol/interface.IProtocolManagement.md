# IProtocolManagement
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/interfaces/IProtocolManagement.sol)

Contains the logic for privileged accounts belonging to CUBE3 to configure the protocol and
Security Modules.


## Functions
### setPausedUnpaused

Updates the paused state of the protocol.

*Emits a {ProtocolPausedStateChange} event.
Notes:
- Convenience function for pausing/unpausing the protocol without having to update
the registry address
- Will not throw if setting the paused state to the current state.
Requirements:
- `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.*


```solidity
function setPausedUnpaused(bool isPaused) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isPaused`|`bool`|Whether to pause the protocol or not.|


### updateProtocolConfig

Updates the protocol configuration.

*Emits {ProtocolConfigUpdated} and conditionally {ProtocolRegistryRemoved} events
Notes:
- We allow the registry to be set to the zero address in the event of a compromised KMS. This will
prevent any new integrations from being registered until the Registry contract is replaced.
- Allows a Protocol Admin to update the Registry and pause the protocol.
- Pausing the protocol prevents new registrations and will force all calls to {Cube3RouterImpl-routeToModule}
to return early.
Requirements:
- `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.
- If not the zero address, the smart contract at `registry` must support the ICube3Registry interface.*


```solidity
function updateProtocolConfig(address registry, bool isPaused) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The address of the Cube3Registry contract.|
|`isPaused`|`bool`|Whether the protocol is paused or not.|


### callModuleFunctionAsAdmin

Calls a function using the calldata provided on the given module.

*Emits any events emitted by the module function being called.
Notes:
- Used to call privileged functions on modules where only the router has access.
- Acts similar to a proxy, except uses `call` instead of `delegatecall`.
- The module address is retrived from storage using the `moduleId`.
Requirements:
- `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.
- The module represented by `moduleId` must be installed.*


```solidity
function callModuleFunctionAsAdmin(
    bytes16 moduleId,
    bytes calldata fnCalldata
)
    external
    payable
    returns (bytes memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The ID of the module to call the function on.|
|`fnCalldata`|`bytes`|The calldata for the function to call on the module.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes`|The return or revert data from the module function call.|


### installModule

Adds a new module to the Protocol.

*Emits an {RouterModuleInstalled} event.
Notes:
- Module IDs are included in the routing bitmap at the tail of the `cube3Payload` and
and are used to dynamically retrieve the contract address for the destination module from storage.
- The Router can only make calls to modules registered via this function.
- Can only install module contracts that have been deployed and support the {ICube3SecurityModule} interface.
Requirements:
- `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE role.
- The `moduleAddress` cannot be the zero address.
- The `moduleAddress` must be a smart contract that supports the ICube3SecurityModule interface.
- The `moduleId` must not contain empty bytes or have been installed before.
- The `moduleId` provided must match the hash of the version string stored in the module contract.
- The module must not have previously been deprecated.*


```solidity
function installModule(address moduleAddress, bytes16 moduleId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleAddress`|`address`|The contract address where the module is located.|
|`moduleId`|`bytes16`|The corresponding module ID generated from the hash of its version string.|


### deprecateModule

Deprecates an installed module.

*Emits {RouterModuleDeprecated} and {RouterModuleRemoved} events.
Notes:
- Deprecation removes the `moduleId` from the list of active modules and adds its to a list
of deprecated modules that ensures it cannot be re-installed.
- If a module is accidentally deprecated, it can be re-installed with a new version string.
- Modules can only be installed by a CUBE3 admin, and can only be deprecatede by an admin,
so a reentrancy guard is not required.
Requirements:
- `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE role.
- The module must currently be installed.
- The call to the {deprecate} function on the module must succeed.*


```solidity
function deprecateModule(bytes16 moduleId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`moduleId`|`bytes16`|The module ID of the module to deprecate.|


