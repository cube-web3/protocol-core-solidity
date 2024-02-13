# Cube3State
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/abstracts/RouterStorage.sol)


```solidity
struct Cube3State {
    Structs.ProtocolConfig protocolConfig;
    mapping(bytes16 moduleId => address module) idToModules;
    mapping(address integration => address pendingAdmin) integrationToPendingAdmin;
    mapping(address integration => Structs.IntegrationState state) integrationToState;
    mapping(address integration => mapping(bytes4 selector => bool isProtected)) integrationToFunctionProtectionStatus;
    mapping(bytes32 signature => bool used) usedRegistrarSignatureHashes;
    mapping(bytes16 moduleId => bool deprecated) deprecatedModules;
}
```

