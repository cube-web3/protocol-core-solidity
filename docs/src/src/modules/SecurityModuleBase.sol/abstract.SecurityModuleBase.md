# SecurityModuleBase
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c68d80b0bdd3201abf24d2487e2b487b223a629b/src/modules/SecurityModuleBase.sol)

**Inherits:**
[ICube3SecurityModule](/src/interfaces/ICube3SecurityModule.sol/interface.ICube3SecurityModule.md), ERC165, [ProtocolConstants](/src/common/ProtocolConstants.sol/abstract.ProtocolConstants.md)

Provides common functionality for all CUBE3 Security Modules.

*See {ICube3SecurityModule} for documentation.*


## State Variables
### cube3router

```solidity
IRouterStorage internal immutable cube3router;
```


### moduleId
Unique ID derived from the module's version string that matches keccak256(abi.encode(moduleVersion));


```solidity
bytes16 public immutable moduleId;
```


### moduleVersion
The human-readable version of the module.

*Module version scheme is as follows: `<module_name>-<semantic_version>`, eg. `signature-0.0.1`
Validation of the moduleVersion string must be done by the deployer*


```solidity
string public moduleVersion;
```


### isDeprecated
Indicates whether the module has been deprecated.


```solidity
bool public isDeprecated;
```


## Functions
### constructor

*During construction, the module makes a call to the router to ensure the version supplied has
not already been installed.*

*The `version` string should be validated for correctness prior to deployment.*


```solidity
constructor(address cubeRouterProxy, string memory version);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`cubeRouterProxy`|`address`|Contract address of the Cube3RouterImpl proxy.|
|`version`|`string`|Human-readable module version, where minimum valid length is 9 bytes and max valid length is 32 bytes: `xxx-x.x.x`|


### onlyCube3Router

*Restricts function calls to the address of the Router Proxy*


```solidity
modifier onlyCube3Router();
```

### deprecate

Deprecates the module so that it cannot be used or reinstalled.

*Emits a {ModuleDeprecated} event.
Notes:
- Can be overridden in the event additional logic needs to be executed during deprecation. The overriding
function MUST use `onlyCube3Router` modifier to ensure access control mechanisms are applied.
Once a module has been deprecated it cannot be reinstalled in the router.
Requirements:
- `msg.sender` is the CUBE3 Router contract.*


```solidity
function deprecate() public virtual onlyCube3Router returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|The version string of the module.|


### supportsInterface

Checks if the contract implements an interface.


```solidity
function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ICube3SecurityModule, ERC165)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interface identifier, as specified in ERC-165.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|bool `true` if the contract implements `interfaceId`, `false` otherwise.|


### _isValidVersionSchema

Checks the version string provided conforms to a specific schema.
Notes:
- Module installation is infrequent and performed by CUBE3, so the slightly elevated gas cost
of this check is acceptable given the operational significance.
- Is NOT a comprehensive validation. Validation on the schema should be done in the deployment script.
- A minimal check evaluating that the version string conforms to the schema: {xxx-x.x.x}
- Checks for the correct version schema by counting the "." separating MAJOR.MINOR.PATCH
- Checks for the presence of the single "-" separating name and version number
- Known exception is omitting semver numbers, eg {xxxxxx-x.x.} or {xxxxx-x..x}


```solidity
function _isValidVersionSchema(string memory version_) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`version_`|`string`|The version string.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the string confirms to the schema: 'true` for yes and 'false' for no.|


