# SignatureUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/libs/SignatureUtils.sol)

Contains utils for signature validation using ECDSA.


## Functions
### assertIsValidSignature


```solidity
function assertIsValidSignature(bytes memory signature, bytes32 digest, address signer) internal pure;
```

