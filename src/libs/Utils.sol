// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library Utils {
    using ECDSA for bytes32;

    event log_named_uint(string name, uint256 value);
    event LogMsgData(bytes msgData);
    event LogDigsest(bytes32 digest);
    event log_module_id(bytes16 id);
    event log_SeclectoR(bytes4 selector);

    /// @notice Extracts the CUBE3 payload, which itself contains the module payload and bitmap containing the routing data.
    /// @dev The `integrationCalldata` is the calldata for the integration contract's function call.
    ///      The cube3payload is present at the end of the calldata as it's passed as the final argument in teh fn call. Noting
    ///      that due to the dynamic encoding of the calldata, the 32 bytes preceding the payload store its length.
    /// @dev The cube3Payload always contains: <module_payload> | <routing_bitmap>
    /// @dev The routing bitmap is a uint256 that contains the following data: <module_padding> | <module_length> | <module_selector> | <module_id>
    function extractPayloadDataFromMsgData(bytes calldata integrationCalldata)
        internal
        pure
        returns (bytes4 moduleSelector, bytes16 moduleId, bytes memory modulePayload, bytes32 originalCalldataDigest)
    {

        // extract the bitmap from the last word of the integration calldat
        uint256 routingBitmap =
            uint256(bytes32(integrationCalldata[integrationCalldata.length - 32:integrationCalldata.length]));

        // The module ID occupies the right-most 16 bytes of the bitmap
        moduleId = extractBytes16Bitmap(routingBitmap);

        // The module selector occupies the 4 bytes to the left of the module ID
        moduleSelector = extractBytes4FromBitmap(routingBitmap, 128);

        // The module length occupies the 4 bytes to the left of the module selector
        uint32 moduleLength = extractUint32FromBitmap(routingBitmap, 160);

        // The module padding occupies the 4 bytes to the left of the module length
        uint32 modulePadding = extractUint32FromBitmap(routingBitmap, 192);

        // Extract the payload from the integration calldata. This will be forwarded on to the module.
        modulePayload =
            integrationCalldata[integrationCalldata.length-moduleLength-32:integrationCalldata.length - modulePadding - 32];

        // Creating a hash of the integration calldata, minus the module payload, can be used to verify the function params used in the function
        // call are equivalent to the ones used to create the signature.
        originalCalldataDigest = keccak256(integrationCalldata[:integrationCalldata.length - moduleLength - 64]);
    }

    /// @notice 
    function extractBytes16Bitmap(uint256 bitmap) internal pure returns (bytes16 moduleId) {
        assembly {
            // Mask to extract the right-most 16 bytes
            let mask := sub(shl(128, 1), 1)
            moduleId := shl(128, and(bitmap, mask))
        }
    }

    function extractUint32FromBitmap(uint256 bitmap, uint256 location) internal pure returns(uint32 value) {
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location', apply mask, and cast to uint32
            value := and(shr(location, bitmap), mask)
        }
    }

    function extractBytes4FromBitmap(uint256 bitmap, uint256 location) internal pure returns(bytes4 value) {
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location' and apply mask
            value := and(shr(location, bitmap), mask)
            value := shl(224, value)
        }
    }

    // TODO: name
    function extractCalledIntegrationFunctionSelector(bytes calldata integrationCalldata)
        internal
        pure
        returns (bytes4 selector)
    {
        selector = bytes4(integrationCalldata[:4]);
    }

    /// @dev Utility function for using ECDSA signature recovery to compare the registrar signer with the
    ///      integration's signing authority (`registrar`).
    /// @dev adminAddress must match msg.sender
    function assertIsValidRegistrar(
        bytes calldata registrarSignature,
        address integrationAdminAddress,
        address integration,
        address registrar
    ) internal view {
        // the hash is generated using the msg.sender,ie the integration contract (or its proxy), and the _self reference, along
        // with the integration's security administrator address, which is retrieved from the contract.
        bytes32 signedHash = keccak256(abi.encodePacked(integration, integrationAdminAddress, block.chainid));
        bytes32 ethSignedHash = signedHash.toEthSignedMessageHash();
        // `tryRecover` returns ECDSA.RecoverError error as the second return value, but we don't need
        // to evaluate as any error returned will return address(0) as the first return value
        (address payloadSigner,) = ethSignedHash.tryRecover(registrarSignature); // 3k gas
        require(payloadSigner != address(0), "CR11: invalid signer");
        require(payloadSigner == registrar, "CR12: not registrar");
    }
}
