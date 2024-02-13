# SignatureUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/libs/SignatureUtils.sol)

Contains utils for signature validation using ECDSA.


## Functions
### assertIsValidSignature


```solidity
function assertIsValidSignature(bytes memory signature, bytes32 digest, address signer) internal pure;
```

