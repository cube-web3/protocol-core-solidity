# ICube3Router

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/interfaces/ICube3Router.sol)

**Author:**
CUBE3.ai

The Cube3RouterImpl extracts routing data from the `cube3SecurePayload` header and
routes transactions to the designated security modules that plugin to the CUBE3 Protocol.

_Integration contracts need to register with the router to be eligible to have
transactions routed to modules._

_The CUBE3_PROTOCOL_ADMIN_ROLE can set the protection status of a deliquent integration to BYPASS, or to REVOKED
for a malicious contract._

_The CUBE3_PROTOCOL_ADMIN_ROLE can install and deprecate modules to extend the functionality
of the router._

_Contract is upgradeable via the Universal Upgradeable Proxy Standard (UUPS)._

_Includes a `__storageGap` to prevent storage collisions following upgrades._

## Functions

### initialize

Initializes the proxy's implementation contract.

_Can only be called during the proxy's construction._

_Omits any argument to avoid changing deployment bytecode across EVM chains._

_See {Cube3RouterProxy-construcot} constructor for implementation details._

```solidity
function initialize() external;
```

### routeToModule

Routes transactions from any Cube3Integration integration to a designated CUBE3 module.

_Can only be called by integration contracts that have registered with the router._

_A successful module function's execution should always return TRUE._

_A failed module function's execution, or not meeting the conditions layed out in the module, should always
revert._

_Makes a low-level call to the module that includes all relevent data._

```solidity
function routeToModule(
    address integrationMsgSender,
    address integrationSelf,
    uint256 integrationMsgValue,
    uint256 cube3PayloadLength,
    bytes calldata integrationMsgData
)
    external
    returns (bool);
```

**Parameters**

| Name                   | Type      | Description                                                                            |
| ---------------------- | --------- | -------------------------------------------------------------------------------------- |
| `integrationMsgSender` | `address` | The msgSender of the originating Cube3Integration function.                            |
| `integrationSelf`      | `address` | The Cube3Integration integration contract address, passes by itself as the \_self ref. |
| `integrationMsgValue`  | `uint256` | The msg.value of the originating Cube3Integration function call.                       |
| `cube3PayloadLength`   | `uint256` | The length of the CUBE3 payload.                                                       |
| `integrationMsgData`   | `bytes`   |                                                                                        |

**Returns**

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| `<none>` | `bool` | Whether the module's function execution was successful. |

### initiate2StepIntegrationRegistration

Registers the calling contract's address as an integration.

_Cannot be called by a contract's constructor as the `supportsInterface` callback would fail._

_Can only be called by a contract, EOAS are prevented from calling via {supportsInterface} callback._

_There is no guarantee the calling contract is a legitimate Cube3Integration contract._

_The registrarSignature needs to be attained from the CUBE3 service._

_msg.sender will be the proxy contract, not the implementation, if it is a proxy registering._

_Unauthorized contracts can be revoked manually by an admin, see {setIntegrationAuthorizationStatus}._

```solidity
function initiate2StepIntegrationRegistration(
    address integrationSelf,
    bytes calldata registrarSignature
)
    external
    returns (bool success);
```

**Parameters**

| Name                 | Type      | Description                                                                 |
| -------------------- | --------- | --------------------------------------------------------------------------- |
| `integrationSelf`    | `address` | The contract address of the integration contract being registered.          |
| `registrarSignature` | `bytes`   | The registration signature provided by the integration's signing authority. |

### setIntegrationRegistrationStatus

Manually sets/updates the designated integration contract's registration status.

_Can only be called by a CUBE3 admin._

_Can be used to reset an upgradeable proxy implementation's registration status._

_If the integration is a standalone contract (not using a proxy), the `integrationOrProxy` and
`integrationOrImplementation` parameters will be the same address._

```solidity
function setIntegrationRegistrationStatus(
    address integrationOrProxy,
    address integrationOrImplementation,
    Structs.RegistrationStatusEnum registrationStatus
)
    external;
```

**Parameters**

| Name                          | Type                             | Description                                                                                   |
| ----------------------------- | -------------------------------- | --------------------------------------------------------------------------------------------- |
| `integrationOrProxy`          | `address`                        | The contract address of the integration contract (or its proxy).                              |
| `integrationOrImplementation` | `address`                        | The contract address of the integration's implementation contract (or itself if not a proxy). |
| `registrationStatus`          | `Structs.RegistrationStatusEnum` | The registration status status to set.                                                        |

### setProtocolContracts

Sets the CUBE3 protocol contract addresses.

_Performs checks using {supportsInterface} to ensure the correct addresses are passed in._

_We cannot pass in the addresses during intialization, as we need the deployed bytecode to be the same
on all EVM chains for use with the constant address deployer proxy._

_MUST be called immediately after deployment, before any other functions are called._

```solidity
function setProtocolContracts(address cube3GateKeeper, address cube3RegistryProxy) external;
```

**Parameters**

| Name                 | Type      | Description                                      |
| -------------------- | --------- | ------------------------------------------------ |
| `cube3GateKeeper`    | `address` | The address of the Cube3GateKeeper contract.     |
| `cube3RegistryProxy` | `address` | The address of the Cube3Registry proxy contract. |

### installModule

Adds a new module to the Protocol.

_Can only be called by CUBE3 admin._

_Module IDs are included in the `cube3SecurePayload` and used to dynamically retrieve
the contract address for the destination module._

_The Router can only make calls to modules registered via this function._

_Can only install module contracts that have been deployed and support the {ICube3SecurityModule} interface._

_Makes a call to the module that returns the string version to validate the module exists._

```solidity
function installModule(address moduleAddress, bytes16 moduleId) external;
```

**Parameters**

| Name            | Type      | Description                                                                |
| --------------- | --------- | -------------------------------------------------------------------------- |
| `moduleAddress` | `address` | The contract address where the module is located.                          |
| `moduleId`      | `bytes16` | The corresponding module ID generated from the hash of its version string. |

### deprecateModule

Deprecates a mondule installed via [installModule](/src/interfaces/ICube3Router.sol/interface.ICube3Router.md#installmodule).

_Can only be called by a Cube3 admin._

_Deletes the module Id from the `idToModules` map._

_A deprecated module cannot be re-installed, either accidentally or intentionally, a newer
version must be deployed._

```solidity
function deprecateModule(bytes16 moduleId) external;
```

**Parameters**

| Name       | Type      | Description                 |
| ---------- | --------- | --------------------------- |
| `moduleId` | `bytes16` | The module ID to deprecate. |

### getModuleAddressById

Gets the contract address of a module using its computed ID.

_`moduleId` is computed from keccak256(abi.encode(versionString))._

```solidity
function getModuleAddressById(bytes16 moduleId) external view returns (address);
```

**Parameters**

| Name       | Type      | Description                                                           |
| ---------- | --------- | --------------------------------------------------------------------- |
| `moduleId` | `bytes16` | The module's ID derived from the hash of the module's version string. |

**Returns**

| Name     | Type      | Description                    |
| -------- | --------- | ------------------------------ |
| `<none>` | `address` | The module contract's address. |

### isProtectedIntegration

Whether the supplied contract is both a registered integration and has a protection status of ACTIVE.

```solidity
function isProtectedIntegration(
    address integrationOrProxy,
    address integrationOrImplementation
)
    external
    view
    returns (bool);
```

**Parameters**

| Name                          | Type      | Description                                                                    |
| ----------------------------- | --------- | ------------------------------------------------------------------------------ |
| `integrationOrProxy`          | `address` | The contract address of the integration (or its proxy) contract being queried. |
| `integrationOrImplementation` | `address` | The contract address of the integration's implementation contract.             |

**Returns**

| Name     | Type   | Description                                             |
| -------- | ------ | ------------------------------------------------------- |
| `<none>` | `bool` | Whether the provided integration is actively protected. |

### getImplementation

Get the current proxy implementation's address.

_Will return the address of the Cube3RouterProxy's current implementation/logic contract._

_Conforms to the UUPS spec._

```solidity
function getImplementation() external view returns (address);
```

**Returns**

| Name     | Type      | Description                                                  |
| -------- | --------- | ------------------------------------------------------------ |
| `<none>` | `address` | The contract address of this active implementation contract. |

### getIntegrationAdmin

```solidity
function getIntegrationAdmin(address integration) external view returns (address);
```

### registerIntegrationWithCube3

```solidity
function registerIntegrationWithCube3(
    address integration,
    bytes calldata registrarSignature,
    bytes4[] calldata enabledByDefaultFnSelectors
)
    external;
```

### getRegistryAddress

```solidity
function getRegistryAddress() external view returns (address);
```

### fetchRegistryAndSigningAuthorityForIntegration

```solidity
function fetchRegistryAndSigningAuthorityForIntegration(address integration)
    external
    view
    returns (address registry, address authority);
```

## Events

### IntegrationRegistrationRevocationStatusUpdated

Emitted when an integration's revocation status is updated.

_Recovation status will be {True} when the integration is revoked and {False} when the revocation is cleared_

```solidity
event IntegrationRegistrationRevocationStatusUpdated(address indexed integration, bool isRevoked);
```

**Parameters**

| Name          | Type      | Description                                                  |
| ------------- | --------- | ------------------------------------------------------------ |
| `integration` | `address` | The integration contract whose revocation status is updated. |
| `isRevoked`   | `bool`    | Whether the `integration` contract is revoked.               |

### RouterModuleInstalled

Emitted when a Cube3 admin installs a new module.

```solidity
event RouterModuleInstalled(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);
```

**Parameters**

| Name            | Type      | Description                                                                               |
| --------------- | --------- | ----------------------------------------------------------------------------------------- |
| `moduleId`      | `bytes32` | The module's computed ID.                                                                 |
| `moduleAddress` | `address` | The contract address of the module.                                                       |
| `version`       | `string`  | A string representing the modules version in the form `<module_name>-<semantic_version>`. |

### RouterModuleDeprecated

Emitted when a Cube3 admin deprecates an installed module.

```solidity
event RouterModuleDeprecated(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);
```

**Parameters**

| Name            | Type      | Description                                             |
| --------------- | --------- | ------------------------------------------------------- |
| `moduleId`      | `bytes32` | The computed ID of the module that was deprecated.      |
| `moduleAddress` | `address` | The contract address of the module that was deprecated. |
| `version`       | `string`  | The human-readable version of the deprecated module.    |

### Cube3ProtocolContractsUpdated

```solidity
event Cube3ProtocolContractsUpdated(address indexed gateKeeper, address indexed registry);
```
