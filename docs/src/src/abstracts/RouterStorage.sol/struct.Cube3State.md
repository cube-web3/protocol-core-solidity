# Cube3State
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/abstracts/RouterStorage.sol)


```solidity
struct Cube3State {
    Structs.ProtocolConfig protocolConfig;
    mapping(bytes16 => address) idToModules;
    mapping(address => address) integrationToPendingAdmin;
    mapping(address => Structs.IntegrationState) integrationToState;
    mapping(address => mapping(bytes4 => bool)) integrationToFunctionProtectionStatus;
    mapping(bytes32 => bool) usedRegistrarSignatureHashes;
}
```

