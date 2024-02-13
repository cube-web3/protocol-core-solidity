# RoutingUtils
[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/c95be0ef92f4c69dc0af4db320cb041b877ea57c/src/libs/RoutingUtils.sol)

Contains utils for extracting a Module Payload and routing data from calldata.


## Functions
### parseRoutingInfoAndPayload

Extracts the CUBE3 payload, which itself contains the module payload and bitmap containing the routing
data.

*The `integrationCalldata` is the calldata for the integration contract's function call.
The cube3payload is present at the end of the calldata as it's passed as the final argument in teh fn call.
Noting
that due to the dynamic encoding of the calldata, the 32 bytes preceding the payload store its length.*

*The cube3Payload always contains: <module_payload> | <routing_bitmap>*

*The routing bitmap is a uint256 that contains the following data: <module_padding> | <module_length> |
<module_selector> | <module_id>*


```solidity
function parseRoutingInfoAndPayload(bytes calldata integrationCalldata)
    internal
    pure
    returns (bytes4 moduleSelector, bytes16 moduleId, bytes memory modulePayload, bytes32 originalCalldataDigest);
```

### parseIntegrationFunctionCallSelector


```solidity
function parseIntegrationFunctionCallSelector(bytes calldata integrationCalldata)
    internal
    pure
    returns (bytes4 selector);
```

