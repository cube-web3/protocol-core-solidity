# RouterStorage
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/abstracts/RouterStorage.sol)

**Inherits:**
[ProtocolEvents](/src/common/ProtocolEvents.sol/abstract.ProtocolEvents.md), [ProtocolAdminRoles](/src/common/ProtocolAdminRoles.sol/abstract.ProtocolAdminRoles.md)

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

### getIntegrationStatus

gets whether the integration has had its registration status revoked


```solidity
function getIntegrationStatus(address integration) public view returns (Structs.RegistrationStatusEnum);
```

### getIntegrationPendingAdmin

gets whether the `account` provided is the pending admin for `integration`


```solidity
function getIntegrationPendingAdmin(address integration) public view returns (address);
```

### getIntegrationAdmin

gets the whether the `account` provided is the admin for `integration`


```solidity
function getIntegrationAdmin(address integration) public view returns (address);
```

### getIsProtocolPaused

gets whether the protocol is paused


```solidity
function getIsProtocolPaused() public view returns (bool);
```

### getModuleAddressById


```solidity
function getModuleAddressById(bytes16 moduleId) public view returns (address);
```

### getRegistrarSignatureHashExists


```solidity
function getRegistrarSignatureHashExists(bytes32 signatureHash) public view returns (bool);
```

### getProtocolConfig


```solidity
function getProtocolConfig() external view returns (Structs.ProtocolConfig memory);
```

### getRegistryAddress


```solidity
function getRegistryAddress() public view returns (address);
```

### _setProtocolConfig


```solidity
function _setProtocolConfig(address registry, bool isPaused) internal;
```

### _setPendingIntegrationAdmin

*`currentAdmin` should always be `msg.sender`.*


```solidity
function _setPendingIntegrationAdmin(address integration, address currentAdmin, address pendingAdmin) internal;
```

### _setIntegrationAdmin


```solidity
function _setIntegrationAdmin(address integration, address newAdmin) internal;
```

### _setFunctionProtectionStatus


```solidity
function _setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) internal;
```

### _setIntegrationRegistrationStatus


```solidity
function _setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) internal;
```

### _setModuleInstalled


```solidity
function _setModuleInstalled(bytes16 moduleId, address moduleAddress, string memory version) internal;
```

### _setUsedRegistrationSignatureHash


```solidity
function _setUsedRegistrationSignatureHash(bytes32 signatureHash) internal;
```

### _deleteIntegrationPendingAdmin


```solidity
function _deleteIntegrationPendingAdmin(address integration) internal;
```

### _deleteInstalledModule


```solidity
function _deleteInstalledModule(bytes16 moduleId, address deprecatedModuleAddress, string memory version) internal;
```

