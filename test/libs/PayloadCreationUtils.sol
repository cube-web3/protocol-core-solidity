// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library PayloadCreationUtils {

 uint256 constant SIGNATURE_MODULE_PAYLOAD_SIZE = 352;

   /*
     Creating a CUBE3 payload involves the following steps:
     - creating the signature by hashing the verifiable data and signing it
     - creating the module payload by packing the following:
       - expirationTimestamp
       - shouldTrackNonce
       - nonce
       - signature
     - calculate the amount of padding required to fill the module payload to the next word {modulePaddingUsed}
     - create the routing bitmap by packing the following:
       - moduleID (bytes16)
       - moduleSelector (butes4)
       - modulePayloadLength (uint32)
       - modulePaddingUsed (uint32)
     - create the packedModulePayload by concatenating the modulePayload and the padding
     - combining packedModulePayload + routingBitmap by packing them to create the cube3Payload
   */

    // TODO: use safe cast
    function calculateRequiredModulePayloadPadding(uint256 modulePayloadLength) internal pure returns (uint32) {
        // calculate the padding needed to fill it to the final word
        return uint32((32 - (modulePayloadLength % 32)) % 32);
    }

    function createPaddedModulePayload(bytes memory modulePayload, uint32 modulePaddingSize) internal pure returns (bytes memory) {
        // pad the module payload to the next word
        bytes memory payloadWithPadding = new bytes(modulePayload.length + modulePaddingSize);

        // only fill the data up until the payload lenght, the rest will be 0s (matching the paddingLength)
        for (uint256 i = 0; i < modulePayload.length;) {
            payloadWithPadding[i] = modulePayload[i];
            unchecked {
                ++i;
            }
        }

        return payloadWithPadding;
    }

    function createRoutingFooterBitmap(
        bytes16 id,
        bytes4 moduleSelector,
        uint32 modulePayloadLength,
        uint32 modulePadding
    )
        internal
        pure
        returns (uint256)
    {
        /*
            stores 4 values in a single word (as a uint256) using a bitmap, where:
            4: empty<4bytes|32bits>
            3: modulePadding<4bytes|32bits>
            2: modulePayloadLength<4bytes|32bits>
            1: moduleSelector<4bytes|32bits
            0: moduleId<16bytes|128bits>

            | xxxxx | xxxxx | xxxxx | xxxxx | xxxxxxxxxxxxxxx
    index:    |_4_|   |_3_|   |_2_|   |_1_|   |______0______|
    bytes:      4       4       4       4           16
        */

        uint256 bitmap = uint256(0);

        // add the module ID in the right-most 16 bytes
        // bitmap = bitmap + uint256(uint128(id));
        bitmap = addBytes16ToBitmap(bitmap, id, 0);

        // add the module selector in the next 4 bytes
        // bitmap = bitmap + (uint256(uint32(moduleSelector)) << 128);
        bitmap = addUint32ToBitmap(bitmap, uint32(moduleSelector), 128);

        // add the module payload length in the next 4 bytes
        // bitmap = bitmap + (uint256(uint32(modulePayloadLength)) << 160);
        bitmap = addUint32ToBitmap(bitmap, uint32(modulePayloadLength), 160);

        // add the cube payload length in the next 4 bytes
        // bitmap = bitmap + (uint256(uint32(modulePadding)) << 192);
        bitmap = addUint32ToBitmap(bitmap, uint32(modulePadding), 192);

        return bitmap;
    }

    function addBytes16ToBitmap(uint256 bitmap, bytes16 id, uint8 offset) public pure returns (uint256) {
        return bitmap + uint256(uint128(id)) << offset;
    }

    function addUint32ToBitmap(uint256 bitmap, uint32 value, uint8 offset) public pure returns (uint256) {
        return bitmap + uint256(value) << offset;
    }


    function sliceBytes(bytes memory _bytes, uint256 start, uint256 end) public pure returns (bytes memory) {
        require(_bytes.length >= end, "Slice end too high");

        bytes memory tempBytes = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            tempBytes[i] = _bytes[i + start];
        }
        return tempBytes;
    }
}