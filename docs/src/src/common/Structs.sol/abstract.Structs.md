# Structs
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/common/Structs.sol)

Defines shared datastructures and enums for the Protocol.


## Structs
### IntegrationState
Structure for storing the state of an integration.


```solidity
struct IntegrationState {
    address admin;
    RegistrationStatusEnum registrationStatus;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`admin`|`address`|The admin account of the integration is represents.|
|`registrationStatus`|`RegistrationStatusEnum`||

### FunctionProtectionStatusUpdate
Represents a request to update the protection status of a specific function within an integration.


```solidity
struct FunctionProtectionStatusUpdate {
    bytes4 fnSelector;
    bool protectionEnabled;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`fnSelector`|`bytes4`|The function selector (first 4 bytes of the keccak256 hash of the function signature) targeted for protection status update.|
|`protectionEnabled`|`bool`|Boolean indicating whether the protection for the specified function is to be enabled (true) or disabled (false).|

### ProtocolConfig
Holds the configuration settings of the Protocol.


```solidity
struct ProtocolConfig {
    address registry;
    bool paused;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The address of the Protocol's registry contract, central to configuration and integration management.|
|`paused`|`bool`|Boolean indicating the operational status of the Protocol; when true, the Protocol is paused, disabling certain operations.|

### TopLevelCallComponents
Aggregates essential components of a top-level call to any of the Protocol's security modules.


```solidity
struct TopLevelCallComponents {
    address msgSender;
    address integration;
    uint256 msgValue;
    bytes32 calldataDigest;
}
```

**Properties**

|Name|Type|Description|
|----|----|-----------|
|`msgSender`|`address`|The original sender of the top-level transaction.|
|`integration`|`address`|The address of the integration contract being interacted with.|
|`msgValue`|`uint256`|The amount of Ether (in wei) sent with the call.|
|`calldataDigest`|`bytes32`|A digest of the call data, providing an integrity check and identity for the transaction's calldata.|

## Enums
### RegistrationStatusEnum
Defines the status of the integration and its relationship with the CUBE3 Protocol.
Notes:
- Defines the integration's level of access to the Protocol.
- An integration can only attain the REGISTERED status receiving a registration signature from the CUBE3
service off-chain.


```solidity
enum RegistrationStatusEnum {
    UNREGISTERED,
    PENDING,
    REGISTERED,
    REVOKED
}
```

