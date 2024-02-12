# RoutingUtils

[Git Source](https://github.com/cube-web3/protocol-core-solidity/blob/07ba602bddefe3eb8d740b07000837f7ec2fa9f5/src/libs/RoutingUtils.sol)

## Functions

### parseRoutingInfoAndPayload

Extracts the CUBE3 payload, which itself contains the module payload and bitmap containing the routing
data.

_The `integrationCalldata` is the calldata for the integration contract's function call.
The cube3payload is present at the end of the calldata as it's passed as the final argument in teh fn call.
Noting
that due to the dynamic encoding of the calldata, the 32 bytes preceding the payload store its length._

_The cube3Payload always contains: <module_payload> | <routing_bitmap>_

_The routing bitmap is a uint256 that contains the following data: <module_padding> | <module_length> |
<module_selector> | <module_id>_

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
