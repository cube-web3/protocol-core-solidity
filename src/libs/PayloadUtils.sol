// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { BitmapUtils } from "./BitmapUtils.sol";

// TODO: rename ModulePayloadUtils
library PayloadUtils {
    using BitmapUtils for uint256;

    /// @notice Extracts the CUBE3 payload, which itself contains the module payload and bitmap containing the routing
    /// data.
    /// @dev The `integrationCalldata` is the calldata for the integration contract's function call.
    ///      The cube3payload is present at the end of the calldata as it's passed as the final argument in teh fn call.
    /// Noting
    ///      that due to the dynamic encoding of the calldata, the 32 bytes preceding the payload store its length.
    /// @dev The cube3Payload always contains: <module_payload> | <routing_bitmap>
    /// @dev The routing bitmap is a uint256 that contains the following data: <module_padding> | <module_length> |
    /// <module_selector> | <module_id>

    function parseRoutingInfoAndPayload(bytes calldata integrationCalldata)
        internal
        pure
        returns (
            bytes4 moduleSelector,
            bytes16 moduleId,
            bytes memory modulePayload,
            bytes32 originalCalldataDigest
        )
    {
        // Extract the bitmap from the last word of the integration calldata.
        uint256 routingBitmap =
            uint256(bytes32(integrationCalldata[integrationCalldata.length - 32:integrationCalldata.length]));

        // The module ID occupies the right-most 16 bytes of the bitmap
        moduleId = routingBitmap.extractBytes16Bitmap();

        // The module selector occupies the 4 bytes to the left of the module ID
        moduleSelector = routingBitmap.extractBytes4FromBitmap(128);

        // The module length occupies the 4 bytes to the left of the module selector
        uint32 moduleLength = routingBitmap.extractUint32FromBitmap(160);

        // The module padding occupies the 4 bytes to the left of the module length
        uint32 modulePadding = routingBitmap.extractUint32FromBitmap(192);

        // Extract the payload from the integration calldata. This will be forwarded on to the module.
        modulePayload = integrationCalldata[
            integrationCalldata.length - moduleLength - 32:integrationCalldata.length - modulePadding - 32
        ];

        // Creating a hash of the integration calldata, minus the module payload, can be used to verify the function
        // params used in the function
        // call are equivalent to the ones used to create the signature.
        originalCalldataDigest = keccak256(integrationCalldata[:integrationCalldata.length - moduleLength - 64]);
    }

    function parseIntegrationFunctionCallSelector(bytes calldata integrationCalldata)
        internal
        pure
        returns (bytes4 selector)
    {
        selector = bytes4(integrationCalldata[:4]);
    }
}
