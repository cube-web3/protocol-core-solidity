# ProtocolAdminRoles
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/common/ProtocolAdminRoles.sol)

Defines privileged roles for controlled access to Protocol functions.


## State Variables
### CUBE3_PROTOCOL_ADMIN_ROLE
Privileged role for making protocol-level changes.


```solidity
bytes32 public constant CUBE3_PROTOCOL_ADMIN_ROLE = keccak256("CUBE3_PROTOCOL_ADMIN_ROLE");
```


### CUBE3_INTEGRATION_MANAGER_ROLE
Privileged role for making integration-level changes.


```solidity
bytes32 public constant CUBE3_INTEGRATION_MANAGER_ROLE = keccak256("CUBE3_INTEGRATION_MANAGER_ROLE");
```


### CUBE3_KEY_MANAGER_ROLE
EOA acting on behalf of the KMS, responsible for managing signing authorities


```solidity
bytes32 public constant CUBE3_KEY_MANAGER_ROLE = keccak256("CUBE3_KEY_MANAGER_ROLE");
```


