# ICube3RouterImpl
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/interfaces/ICube3RouterImpl.sol)

Contains the collective logic for the {Cube3RouterImpl} contract and the contracts it inherits from:
{ProtocolManagement}, {IntegrationManagement}, and {RouterStorage}.

*All events are defined in {ProtocolEvents}.*


## Functions
### getImplementation

Used to retrieve the implementation address of the proxy.

*Utilizes [ERC1967Utils-getImplementation](/lib/openzeppelin-contracts-upgradeable/lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Utils.sol/library.ERC1967Utils.md#getimplementation)*


```solidity
function getImplementation() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|The address of the implementation contract.|


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
function initialize(address registry) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`registry`|`address`|The address of the CUBE3 Registry contract.|


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


### supportsInterface

Checks whether the ICube3Router interface is supported.


```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`interfaceId`|`bytes4`|The interfaceId to check.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether the provided interface is supported: `true` for yes.|


