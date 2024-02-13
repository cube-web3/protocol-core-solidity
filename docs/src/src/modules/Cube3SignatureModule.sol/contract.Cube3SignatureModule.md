# Cube3SignatureModule
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/modules/Cube3SignatureModule.sol)

**Inherits:**
[SecurityModuleBase](/src/modules/SecurityModuleBase.sol/abstract.SecurityModuleBase.md), [ICube3SignatureModule](/src/interfaces/ICube3SignatureModule.sol/interface.ICube3SignatureModule.md)

This Secuity Module contains logic for validating signatures provided by CUBE3's
RASP service.

*See {ICube3SignatureModule} for documentation.*


## State Variables
### _universalSigner

```solidity
address private immutable _universalSigner;
```


### integrationToUserNonce

```solidity
mapping(address integration => mapping(address integrationMsgSender => uint256 userNonce)) internal
    integrationToUserNonce;
```


## Functions
### constructor

*Passes the `cubeRouterProxy` address and `version` string to the {Cube3Module} constructor.*


```solidity
constructor(
    address cube3RouterProxy,
    string memory version,
    address backupSigner
)
    SecurityModuleBase(cube3RouterProxy, version);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`cube3RouterProxy`|`address`|The address of the Cube3RouterImpl proxy.|
|`version`|`string`|Human-readable module version used to generate the module's ID.|
|`backupSigner`|`address`|Backup payload signer in the event the registry is removed.|


### validateSignature

Validates the signature and data signed by the Integration's
signing authority.

*Emits no events as a gas-saving measure.
Notes:
- If the Registry has been removed from the Router, the module will fallback
to using the backup universal signer.
- Acts like an assertion, will revert under any condition except success.
Requirements:
- `msg.sender` must be the CUBE3 Router.
- The integration's signing authority cannot be the zero address.
- The signer recoverd from the signature must match the Integration's signing
authority.
- The payload's expiration timestamp must not exceed the current block.timestamp.*


```solidity
function validateSignature(
    Structs.TopLevelCallComponents memory topLevelCallComponents,
    bytes calldata signatureModulePayload
)
    external
    onlyCube3Router
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`topLevelCallComponents`|`Structs.TopLevelCallComponents`|The details of the top-level call, such as `msg.sender`|
|`signatureModulePayload`|`bytes`|The payload containing the data to be validated by this module.s|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The hashed MODULE_CALL_SUCCEEDED indicating that signature recovery was succeefull.|


### integrationUserNonce

Retrieves the per-integration nonce of the `account` provided

*The nonce will only be incremented if directed by the module payload.*


```solidity
function integrationUserNonce(address integrationContract, address account) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrationContract`|`address`|The integration to retrieve the nonce for.|
|`account`|`address`|The address of the caller to retrieve the nonce for.|


### _fetchSigningAuthorityFromRegistry

*Utility function for retrieving the signing authority from the registry for a given integration*


```solidity
function _fetchSigningAuthorityFromRegistry(
    ICube3Registry cube3registry,
    address integration
)
    internal
    view
    returns (address signer);
```

### _fetchRegistryFromRouter

*Makes an external call to the Cube3RouterImpl to retrieve the registry address.*


```solidity
function _fetchRegistryFromRouter() internal view returns (ICube3Registry);
```

### _getChainID

Util for getting the chain ID.


```solidity
function _getChainID() internal view returns (uint256 id);
```

### _decodeModulePayload

*Utility function for decoding the `cube3SecurePayload` and returning its
constituent elements as a SignatureModulePayloadData struct.*

*Checks the validity of the payloads target function selector, module Id, and expiration.*


```solidity
function _decodeModulePayload(bytes calldata modulePayload) internal view returns (SignatureModulePayloadData memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`modulePayload`|`bytes`|The module payload to decode, created with abi.encodePacked().|


