# AddressUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/libs/AddressUtils.sol)

Contains utility functions for checking what type of accounts an address belongs to.


## Functions
### assertIsContract

Checks if an account is a contract.

*Ensures the target address is a contract. This is done by checking the length
of the bytecode stored at that address. Reverts if the address is not a contract.*


```solidity
function assertIsContract(address target) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|Address to check the bytecode size.|


### assertIsEOAorConstructorCall

Checks if an account is an EOA or a contract under construction.

*Ensures the target address is an EOA, or a contract under construction. Reverts
if the codesize check is failed.*


```solidity
function assertIsEOAorConstructorCall(address target) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|Address to check the bytecode size.|


