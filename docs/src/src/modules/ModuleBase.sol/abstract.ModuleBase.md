# ModuleBase

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/modules/ModuleBase.sol)

**Inherits:**
[ICube3Module](/src/interfaces/ICube3Module.sol/interface.ICube3Module.md), [ModuleBaseEvents](/src/modules/ModuleBaseEvents.sol/abstract.ModuleBaseEvents.md), ERC165, [ProtocolConstants](/src/common/ProtocolConstants.sol/abstract.ProtocolConstants.md)

_See {ICube3Module}_

## State Variables

### cube3router

```solidity
ICube3Router internal immutable cube3router;
```

### moduleVersion

The human-readable version of the module.

_Module version scheme is as follows: `<module_name>-<semantic_version>`, eg. `signature-0.0.1`_

```solidity
string public moduleVersion;
```

### moduleId

```solidity
bytes16 public immutable moduleId;
```

### expectedPayloadSize

```solidity
uint256 public immutable expectedPayloadSize;
```

### isDeprecated

Indicates whether the module has been deprecated.

```solidity
bool public isDeprecated;
```

## Functions

### constructor

_During construction, the module makes a call to the router to ensure the version supplied has
not already been installed._

_The `version` string should be validated for correctness prior to deployment._

```solidity
constructor(address cubeRouterProxy, string memory version, uint256 payloadSize);
```

**Parameters**

| Name              | Type      | Description                                                                                                        |
| ----------------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| `cubeRouterProxy` | `address` | Contract address of the Cube3RouterImpl proxy.                                                                     |
| `version`         | `string`  | Human-readable module version, where minimum valid length is 9 bytes and max valid length is 32 bytes: `xxx-x.x.x` |
| `payloadSize`     | `uint256` |                                                                                                                    |

### onlyCube3Router

_Restricts function calls to the address of the Router Proxy_

```solidity
modifier onlyCube3Router();
```

### deprecate

Deprecates the module.

_Can be overridden in the event additional logic needs to be executed during deprecation._

_Overriden function MUST use `onlyCube3Router` modifier._

```solidity
function deprecate() external virtual onlyCube3Router returns (string memory);
```

**Returns**

| Name     | Type     | Description                                              |
| -------- | -------- | -------------------------------------------------------- |
| `<none>` | `string` | The deprecation status and human-readable module version |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool);
```

### \_isValidVersionSchema

_Module installation is infrequent and performed by CUBE3, so the slightly elevated gas cost
of this check is acceptable given the operational significance._

_Is NOT a comprehensive validation. Validation on the schema should be done in the deployment script._

_A minimal check evaluating that the version string conforms to the schema: {xxx-x.x.x}_

_Checks for the correct version schema by counting the "." separating MAJOR.MINOR.PATCH_

_Checks for the presence of the single "-" separating name and version number_

_Known exception is omitting semver numbers, eg {xxxxxx-x.x.} or {xxxxx-x..x}_

```solidity
function _isValidVersionSchema(string memory version_) internal pure returns (bool);
```
