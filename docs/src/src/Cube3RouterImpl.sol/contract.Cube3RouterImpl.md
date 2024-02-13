# Cube3RouterImpl
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/Cube3RouterImpl.sol)

**Inherits:**
[ICube3RouterImpl](/src/interfaces/ICube3RouterImpl.sol/interface.ICube3RouterImpl.md), ContextUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, [ProtocolManagement](/src/abstracts/ProtocolManagement.sol/abstract.ProtocolManagement.md), [IntegrationManagement](/src/abstracts/IntegrationManagement.sol/abstract.IntegrationManagement.md)

Defines the implementation contract for the upgradeable CUBE3 Router.

*See {ICube3RouterImpl} for documentation, which is inherited implicitly via
{ProtocolManagement} and {IntegrationManagement}.
Notes:
- All storage variables are defined in {RouterStorage} and accessed via
dedicated getter and setter functions.*


## Functions
### onlyConstructor

*Checks the call can only take place in another contract's constructor.*


```solidity
modifier onlyConstructor();
```

### constructor

*Lock the implementation contract at deployment to prevent it being used until
it is initialized.*


```solidity
constructor();
```

### initialize

Initializes the proxy contract.

*Emits a {ProtocolConfigUpdated} event.
Notes:
- Initializes AccessControlUpgradeable
- Initialized UUPSUpgradeable
- Initializes ERC165
- Sets the initial configuration of the protocol.
- Grants the DEFAULT_ADMIN_ROLE to the EOA responsible for deployment. This accounts
for deployment using salted contract creation via a contract.
- The protocol is not paused by default.
Requirements:
- `msg.sender` must be a contract and the call must take place within it's constructor.
- `registry` cannot be the zero address.*


```solidity
function initialize(address registry) public initializer onlyConstructor;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The address of the CUBE3 Registry contract.|


### _authorizeUpgrade

*Adds access control logic to the {upgradeTo} function*


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyRole(CUBE3_PROTOCOL_ADMIN_ROLE);
```

### getImplementation

Used to retrieve the implementation address of the proxy.

*Utilizes {ERC1967Utils-getImplementation}*


```solidity
function getImplementation() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the implementation contract.|


### routeToModule

Routes the top-level calldata to the Security Module using data
embedded in the routing bitmap.

*If events are emitted, they're done so by the Security Module being utilized.
Notes:
- Acts like an assertion.  Will revert on any error or failure to meet the
conditions laid out by the security module.
- Will bypass the security modules under the following conditions, checked
sequentially:
- Function protection for the provided selector is disabled.
- The integration's registration status is revoked.
- The Protocol is paused.
- Only contracts can be registered as integrations, so checking against UNREGISTERED
status is redundant.
- No Ether is transferred to the router, so the function is non-payable.
- If the module function call reverts, the revert data will be relayed to the integration.
Requirements:
- The last word of the `integrationCalldata` is a valid routing bitmap.
- The module identified in the routing bitmap must be installed.
- The call to the Security Module must succeed.*


```solidity
function routeToModule(
    address integrationMsgSender,
    uint256 integrationMsgValue,
    bytes calldata integrationCalldata
)
    external
    returns (bytes32);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrationMsgSender`|`address`|the `msg.sender` of the top-level call.|
|`integrationMsgValue`|`uint256`|The `msg.value` of the top-level call.|
|`integrationCalldata`|`bytes`|The `msg.data` of the top-level call, which includes the CUBE3 Payload.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|The PROCEED_WITH_CALL magic value if the call succeeds.|


### _shouldBypassRouting

Determines whether to forward the relative parts of the calldata to the Security Module.

*There's no need to check for a registration status of PENDING, as an integration's function
protection status cannot be enabled until it's registered, and thus the first condition will always
be false and thus routing should be bypassed.*


```solidity
function _shouldBypassRouting(bytes4 integrationFnCallSelector) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`integrationFnCallSelector`|`bytes4`|The function selector of the top-level call to the integration.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether routing to the module should be bypassed: `true` to bypass the module and return early to the integration, and 'false` to continue on and utilize the Security Module.|


### _executeModuleFunctionCall

Performs the call to the Security Module.

*Reverts under any condition other than a successful return.*


```solidity
function _executeModuleFunctionCall(address module, bytes memory moduleCalldata) internal returns (bytes32);
```

### supportsInterface

Checks whether the ICube3Router interface is supported.


```solidity
function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControlUpgradeable, ICube3RouterImpl)
    returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interfaceId to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the provided interface is supported: `true` for yes.|


