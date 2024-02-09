# Structs
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/common/Structs.sol)


## Structs
### IntegrationState
Defines the state of the integration's state in relation to the protocol.


```solidity
struct IntegrationState {
    address admin;
    RegistrationStatusEnum registrationStatus;
}
```

### FunctionProtectionStatusUpdate

```solidity
struct FunctionProtectionStatusUpdate {
    bytes4 fnSelector;
    bool protectionEnabled;
}
```

### ProtocolConfig

```solidity
struct ProtocolConfig {
    address registry;
    bool paused;
}
```

### IntegrationCallMetadata

```solidity
struct IntegrationCallMetadata {
    address msgSender;
    address integration;
    uint256 msgValue;
    bytes32 calldataDigest;
}
```

## Enums
### RegistrationStatusEnum
Defines the state of the integration's registration status.

*RegistrationStatusEnum refers to the integration's relationship with the CUBE3 protocol.*

*An integration can only register with the protocol by receiving a registration signature from the CUBE3
service off-chain.*


```solidity
enum RegistrationStatusEnum {
    UNREGISTERED,
    PENDING,
    REGISTERED,
    REVOKED
}
```

