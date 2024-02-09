# ProtocolManagement
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/abstracts/ProtocolManagement.sol)

**Inherits:**
AccessControlUpgradeable, [RouterStorage](/src/abstracts/RouterStorage.sol/abstract.RouterStorage.md)

*This contract contains all the logic for managing the protocol*


## Functions
### setProtocolConfig

*We allow the registry to be set to the zero address in the event of a compromise. Removing the
registry will prevent any new integrations from being registered.*


```solidity
function setProtocolConfig(address registry, bool isPaused) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE);
```

### callModuleFunctionAsAdmin

*used to call privileged functions on modules where only the router has access*

*never know if it needs to be payable or not*


```solidity
function callModuleFunctionAsAdmin(
    bytes16 moduleId,
    bytes calldata fnCalldata
)
    external
    payable
    onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE)
    returns (bytes memory);
```

### installModule


```solidity
function installModule(address moduleAddress, bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE);
```

### deprecateModule


```solidity
function deprecateModule(bytes16 moduleId) external onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE);
```

