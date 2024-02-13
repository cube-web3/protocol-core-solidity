# ProtocolConstants
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/common/ProtocolConstants.sol)

Defines unique return values for Protocol actions to be stored in the contract's bytecode.


## State Variables
### MODULE_CALL_SUCCEEDED
Returned by a module when the module successfuly executes its internal logic.


```solidity
bytes32 public constant MODULE_CALL_SUCCEEDED = keccak256("CUBE3_MODULE_CALL_SUCCEEDED");
```


### PRE_REGISTRATION_SUCCEEDED
Returned by the router when the pre-registration of the integration is successful.


```solidity
bytes32 public constant PRE_REGISTRATION_SUCCEEDED = keccak256("CUBE3_PRE_REGISTRATION_SUCCEEDED");
```


### MODULE_CALL_FAILED
Returned by a module when the module's internal logic execution fails.


```solidity
bytes32 public constant MODULE_CALL_FAILED = keccak256("CUBE3_MODULE_CALL_FAILED");
```


### PROCEED_WITH_CALL
Returned by the router if the module call succeeds, the integration is not registered, the protocol is
paused, or


```solidity
bytes32 public constant PROCEED_WITH_CALL = keccak256("CUBE3_PROCEED_WITH_CALL");
```


