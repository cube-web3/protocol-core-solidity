# Cube3RouterImpl

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/Cube3RouterImpl.sol)

**Inherits:**
ContextUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, [ProtocolManagement](/src/abstracts/ProtocolManagement.sol/abstract.ProtocolManagement.md), [IntegrationManagement](/src/abstracts/IntegrationManagement.sol/abstract.IntegrationManagement.md), [ProtocolConstants](/src/common/ProtocolConstants.sol/abstract.ProtocolConstants.md)

_See {ICube3Router}_

_All storage variables are defined in RouterStorage.sol and accessed via dedicated getter and setter functions_

## Functions

### onlyConstructor

_The implementation should only be initialized in the constructor of the proxy_

```solidity
modifier onlyConstructor();
```

### constructor

_lock the implementation contract at deployment to prevent it being used_

```solidity
constructor();
```

### initialize

_Initialization can only take place once, and is called by the proxy's constructor._

```solidity
function initialize(address registry) public initializer onlyConstructor;
```

### \_authorizeUpgrade

_Adds access control logic to the {upgradeTo} function_

```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE);
```

### getImplementation

_returns the proxy's current implementation address_

```solidity
function getImplementation() external view returns (address);
```

### routeToModule

_Routes the module payload contained in the integrationCalldata to the appropriate module, provided
the originating function call's function is protected._

_Will return PROCEED_WITH_CALL if the function is not protected, the integration's registration status is
REVOKED, or the protocol is paused._

_Only contracts can complete registration, so checking the caller is a contract is redundant._

```solidity
function routeToModule(
    address integrationMsgSender,
    uint256 integrationMsgValue,
    bytes calldata integrationCalldata
)
    external
    returns (bytes32);
```

### \_shouldBypassRouting

_Returns whether routing to the module should be bypassed. Note: There's no need to check for a registration
status of PENDING, as an integration's function protection status cannot be enabled until it's registered,
and
thus the first condition will always be false and thus routing should be bypassed._

```solidity
function _shouldBypassRouting(bytes4 integrationFnCallSelector) internal view returns (bool);
```

### \_executeModuleFunctionCall

_Calls the function on `module` with the given calldata. Will revert if the call fails or does
not return the expected success value._

```solidity
function _executeModuleFunctionCall(address module, bytes memory moduleCalldata) internal returns (bytes32);
```

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view override returns (bool);
```
