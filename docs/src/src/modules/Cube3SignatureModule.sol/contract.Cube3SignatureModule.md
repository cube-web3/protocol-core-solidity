# Cube3SignatureModule
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/modules/Cube3SignatureModule.sol)

**Inherits:**
[ModuleBase](/src/modules/ModuleBase.sol/abstract.ModuleBase.md), [ICube3SignatureModule](/src/interfaces/ICube3SignatureModule.sol/interface.ICube3SignatureModule.md)

*see {ICube3SignatureModule}*

*in the unlikely event that the backup signer is compromised, the module should be deprecated
via the router.*


## State Variables
### _universalSigner

```solidity
address private immutable _universalSigner;
```


### integrationToUserNonce

```solidity
mapping(address => mapping(address => uint256)) private integrationToUserNonce;
```


## Functions
### constructor

Initializes the Signature module.

*Passes the `cubeRouterProxy` address and `version` string to the {Cube3Module} constructor.*


```solidity
constructor(
    address cube3RouterProxy,
    string memory version,
    address backupSigner,
    uint256 expectedPayloadSize
)
    ModuleBase(cube3RouterProxy, version, expectedPayloadSize);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`cube3RouterProxy`|`address`|The address of the Cube3Router proxy.|
|`version`|`string`|Human-readable module version used to generate the module's ID|
|`backupSigner`|`address`|Backup payload signer in the event the registry is removed|
|`expectedPayloadSize`|`uint256`||


### validateSignature


```solidity
function validateSignature(
    Structs.IntegrationCallMetadata memory integrationData,
    bytes calldata modulePayload
)
    external
    onlyCube3Router
    returns (bytes32);
```

### integrationUserNonce


```solidity
function integrationUserNonce(address integrationContract, address account) external view returns (uint256);
```

### _getSigningAuthority

*Utility function for retrieving the signing authority from the registry for a given integration*


```solidity
function _getSigningAuthority(
    ICube3Registry cube3registry,
    address integration
)
    private
    view
    returns (address signer);
```

### _getRegistryFromRouter

*Makes an external call to the Cube3Router to retrieve the registry address.*


```solidity
function _getRegistryFromRouter() private view returns (ICube3Registry);
```

### _getChainID


```solidity
function _getChainID() private view returns (uint256 id);
```

### _decodeModulePayload

*Utility function for decoding the `cube3SecurePayload` and returning its
constituent elements as a Cube3SignatureModulePayload struct.*

*Checks the validity of the payloads target function selector, module Id, and expiration.*


```solidity
function _decodeModulePayload(bytes calldata modulePayload) private view returns (Cube3SignatureModulePayload memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`modulePayload`|`bytes`|The module payload to decode, created with abi.encodePacked().|


## Events
### logCube3SignatureModulePayload

```solidity
event logCube3SignatureModulePayload(Cube3SignatureModulePayload payload);
```
