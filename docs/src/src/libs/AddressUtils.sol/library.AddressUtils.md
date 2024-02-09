# AddressUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/libs/AddressUtils.sol)


## Functions
### assertIsContract

*Ensures the target address is a contract. This is done by checking the length
of the bytecode stored at that address. Note: This function will be used to complete
registration, which cannot take place during the contract's deployment, therefore bytecode
length is expected to be non-zero.*


```solidity
function assertIsContract(address target) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`target`|`address`|Address to check the bytecode size.|


### assertIsEOAorConstructorCall


```solidity
function assertIsEOAorConstructorCall(address target) internal view;
```

