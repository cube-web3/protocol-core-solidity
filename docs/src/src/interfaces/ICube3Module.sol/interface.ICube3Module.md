# ICube3SecurityModule

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/interfaces/ICube3SecurityModule.sol)

**Author:**
CUBE3.ai

Provides the module with connectivity to the Cube3RouterImpl and manages the module's versioning.

_All CUBE3 security modules will inherit this base contract._

_This module is used through inheritance._

_Any module that inherits this contract should never make use of `selfdestruct` or
delegatecall to a contract that might, as it could potentially render the router proxy
inoperable._

## Functions

### moduleVersion

The human-readable version of the module.

_Module version scheme is as follows: `<module_name>-<semantic_version>`, eg. `signature-0.0.1`_

_Validation of the moduleVersion string must be done by the deployer_

```solidity
function moduleVersion() external view returns (string memory);
```

**Returns**

| Name     | Type     | Description                    |
| -------- | -------- | ------------------------------ |
| `<none>` | `string` | The module version as a string |

### isDeprecated

Indicates whether the module has been deprecated.

```solidity
function isDeprecated() external view returns (bool);
```

**Returns**

| Name     | Type   | Description                          |
| -------- | ------ | ------------------------------------ |
| `<none>` | `bool` | The deprecation status of the module |

### deprecate

Deprecates the module.

_Only callable by the Cube3RouterImpl._

_Deprecation event emitted by the router, see {Cube3RouterLogic-deprecateModule}._

_Once a module has been deprecated it cannot be reinstalled in the router._

```solidity
function deprecate() external returns (string memory);
```

**Returns**

| Name     | Type     | Description                                              |
| -------- | -------- | -------------------------------------------------------- |
| `<none>` | `string` | The deprecation status and human-readable module version |

### moduleId

Gets the ID of the module

_computes the keccak256 hash of the abi.encoded moduleVersion_

```solidity
function moduleId() external view returns (bytes16);
```

**Returns**

| Name     | Type      | Description              |
| -------- | --------- | ------------------------ |
| `<none>` | `bytes16` | The module's computed ID |
