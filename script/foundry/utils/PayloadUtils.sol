pragma solidity >= 0.8.19 < 0.8.24;

import "forge-std/Test.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Cube3SignatureModule } from "@src/modules/Cube3SignatureModule.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { Structs } from "@src/common/Structs.sol";

contract PayloadUtils is Test {
    using ECDSA for bytes32;

    uint256 internal constant PAYLOAD_LENGTH = 384; // includes length + magic value

    bytes32 private constant CUBE3_PAYLOAD_MAGIC_VALUE = keccak256("CUBE3_PAYLOAD_MAGIC_VALUE");

    constructor() { }

    function _createPayloadSignature(
        bytes memory encodedSignatureData,
        uint256 pvtKeyToSignWith
    )
        internal
        returns (bytes memory signature)
    {
        bytes32 signatureHash = keccak256(encodedSignatureData);
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(signatureHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

        signature = abi.encodePacked(r, s, v);

        assertTrue(signature.length == 65, "invalid signature length");

        (address signedHashAddress, ECDSA.RecoverError error,) = ethSignedHash.tryRecover(signature);
        if (error != ECDSA.RecoverError.NoError) {
            revert("No Matchies");
        }

        assertEq(signedHashAddress, vm.addr(pvtKeyToSignWith), "signers dont match");
    }

    function _createIntegrationCallInfo(
        address caller,
        address integration,
        uint256 msgValue,
        bytes memory integrationCalldataWithEmptyPayload,
        Cube3SignatureModule signatureModule
    )
        internal
        returns (Structs.TopLevelCallComponents memory)
    {
        // remove the payload so we can create a hash of the calldata without the payload,
        // note: because payload is type bytes, the slicedCalldata may contain some data about the payload,
        // eg. the offset to the payload, and the length of the payload, but this will be the case when it's
        // reproduced on chain.  For all intents and purposes, the empty bytes payload is structurally identical
        // to the payload populated with the correct data
        bytes memory slicedCalldata = _sliceBytes(
            integrationCalldataWithEmptyPayload,
            0,
            integrationCalldataWithEmptyPayload.length - signatureModule.expectedPayloadSize() - 64 //
        );
        bytes32 calldataDigest = keccak256(slicedCalldata);

        // emit log_named_bytes("slicedcalldata", slicedCalldata);
        // emit log_named_bytes32("calldatadigest", calldataDigest);

        return Structs.TopLevelCallComponents(caller, integration, msgValue, calldataDigest);
    }

    event LogBytes16(bytes16 b);
    event log_named_uint32(string name, uint32 b);

    function _createPayload(
        address integration,
        address caller,
        uint256 signingAuthPvtKey,
        uint256 expirationWindow,
        Cube3SignatureModule signatureModule,
        Structs.TopLevelCallComponents memory topLevelCallComponents
    )
        internal
        returns (bytes memory)
    {
        uint256 expirationTimestamp = block.timestamp + expirationWindow;
        uint256 userNonce = false ? signatureModule.integrationUserNonce(integration, caller) + 1 : 0;

        // create the signature (ie what's usually handled by the risk API)
        bytes memory encodedSignatureData = abi.encode(
            block.chainid, // chain id
            topLevelCallComponents,
            address(signatureModule), // module contract address
            Cube3SignatureModule.validateSignature.selector, // the module fn's signature
            userNonce,
            expirationTimestamp // expiration
        );

        // don't track the nonce for now
        (bytes memory modulePayload, uint32 modulePadding) = _encodeModulePayloadAndPadToNextFullWord(
            false, userNonce, expirationTimestamp, _createPayloadSignature(encodedSignatureData, signingAuthPvtKey)
        );

        uint256 bitmap = _createRoutingFooterBitmap(
            signatureModule.moduleId(),
            Cube3SignatureModule.validateSignature.selector,
            uint32(modulePayload.length),
            modulePadding
        );

        /*
        {
            bytes4 bitmapSelector = _extractSelectorBytes4FromBitmap(bitmap, 128);
            uint32 bitmapPayloadLength = uint32(_extractSelectorBytes4FromBitmap(bitmap, 160));
            uint32 bitmapCubePayloadLength = uint32(_extractSelectorBytes4FromBitmap(bitmap, 192));

        assertEq(bitmapPayloadLength, _extractSelectorBytes4FromBitmapAssm(bitmap, 160), "bitmap payload length does not
        match");
        assertEq(bitmapCubePayloadLength, _extractSelectorBytes4FromBitmapAssm(bitmap, 192), "bitmap payload length does
        not match");
        }
        // emit log_named_uint32("bitmapPayloadLength", bitmapPayloadLength);
        // emit log_named_uint32("bitmapCubePayloadLength", bitmapCubePayloadLength);
        // emit log_named_bytes4("bitmapSelector", bitmapSelector);
        // emit log_named_uint("bitmap", bitmap);
        bytes16 extractedId = _extractModuleIdFromBitmap(bitmap);
        // emit LogBytes16(extractedId);
        {
            bytes16 assmId = _extractModuleIdFromBitmapAssembly(bitmap);
            // emit LogBytes16(assmId);
            assertEq(extractedId,assmId , "extracted module id does not match");
        }

        {
            bytes16 extractedIdAssembly = _extractModuleIdFromBitmap(bitmap);
            emit LogBytes16(extractedIdAssembly);
            assertEq(extractedId, extractedIdAssembly, "extracted module id does not match");
        }
        */
        // bytes memory cube3Payload = abi.encodePacked(modulePayload, bitmap);
        // emit log_named_bytes("cube3Payload", cube3Payload);
        return abi.encodePacked(modulePayload, bitmap);
    }

    function _sliceBytes(bytes memory _bytes, uint256 start, uint256 end) public pure returns (bytes memory) {
        require(_bytes.length >= end, "Slice end too high");

        bytes memory tempBytes = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            tempBytes[i] = _bytes[i + start];
        }
        return tempBytes;
    }

    function _encodeModulePayloadAndPadToNextFullWord(
        bool trackNonce,
        uint256 nonce,
        uint256 expirationTimestamp,
        bytes memory signature
    )
        internal
        returns (bytes memory, uint32)
    {
        // Construct the CubePayload
        // we don't need the verfied calldata, because the actual call data is used to reconstruct the hash that gets
        // signed on-chain
        bytes memory modulePayload = abi.encodePacked(
            expirationTimestamp,
            trackNonce, // whether to track the nonce
            nonce,
            signature
        );
        // emit log_named_bytes("modulePayloadWithoutPadding", modulePayload);

        // calculate the padding needed to fill it to the final word
        uint256 paddingNeeded = _calculateRequiredPadding(modulePayload.length);
        // emit log_named_uint("paddingNeeded", paddingNeeded);

        bytes memory payloadWithPadding = new bytes(modulePayload.length + paddingNeeded);

        // only fill the data up until the payload lenght, the rest will be 0s (matching the paddingLength)
        for (uint256 i = 0; i < modulePayload.length;) {
            payloadWithPadding[i] = modulePayload[i];
            unchecked {
                ++i;
            }
        }
        emit log_named_bytes("payloadWithPadding", payloadWithPadding);
        return (payloadWithPadding, uint32(paddingNeeded));
    }

    // enum BitMapItemIndex {
    //     MODULE_ID = 32,
    //     PADDING = 16,
    //     CUBE_PAYLOAD_LENGTH= 12,
    //     MODULE_PAYLOAD_LENGTH = 8,
    //     MODULE_SELECTOR = 4
    // }

    function _calculateRequiredPadding(uint256 modulePayloadLength) internal pure returns (uint256) {
        // calculate the padding needed to fill it to the final word
        return (32 - (modulePayloadLength % 32)) % 32;
    }

    function _createRoutingFooterBitmap(
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
        bitmap = bitmap + uint256(uint128(id));

        // add the module selector in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(moduleSelector)) << 128);

        // add the module payload length in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(modulePayloadLength)) << 160);

        // add the cube payload length in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(modulePadding)) << 192);

        return bitmap;
    }

    function _extractModuleIdFromBitmapAssembly(uint256 bitmap) internal pure returns (bytes16) {
        bytes16 moduleId;
        assembly {
            // Mask to extract the right-most 16 bytes
            let mask := sub(shl(128, 1), 1)
            moduleId := shl(128, and(bitmap, mask))
        }
        return moduleId;
    }

    function _extractModuleIdFromBitmap(uint256 bitmap) internal returns (bytes16) {
        // no need to shift right as we're only interested in the right-most 16 bytes

        uint256 mask = (uint256(1) << 128) - 1;
        emit log_named_uint("mask", mask);
        uint256 moduleUint = bitmap & mask;
        moduleUint = moduleUint << 128;
        bytes32 moduleBytes32 = bytes32(moduleUint);
        emit log_named_bytes32("moduleBytes32", moduleBytes32);
        emit log_named_uint("moduleUint", moduleUint);
        return bytes16(bytes32(moduleUint));
    }

    event log_named_bytes4(string name, bytes4 b);

    // `location` is the number of bits distance from the least significant bit (right-most)
    function _extractSelectorBytes4FromBitmap(uint256 bitmap, uint256 location) internal returns (bytes4) {
        uint256 numberOfTargetBits = 32;
        uint256 mask = (uint256(1) << numberOfTargetBits) - 1;
        emit log_named_uint("mask", mask);

        uint256 selectorUint = (bitmap >> location) & mask;

        // when casting from uint256 to bytes4, we need to make sure our 32bits occupy the most significant bits, so
        // shift left to the 32 most significant bits
        selectorUint = selectorUint << 224;
        emit log_named_uint("selectorUint", selectorUint);

        bytes4 converted = bytes4(bytes32(selectorUint));
        emit log_named_bytes4("selectorBytes4", converted);

        return converted;
    }

    function _extractSelectorBytes4FromBitmapAssm(uint256 bitmap, uint256 location) internal pure returns (uint32) {
        uint32 selector;
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location', apply mask, and cast to uint32
            selector := and(shr(location, bitmap), mask)
        }
        return selector;
    }

    // function _extractSelectorFromBitmap(uint256 bitmap) internal returns(bytes4) {
    //     uint256 numberOfTargetBits = 32;
    //     uint256 mask = (uint256(1) << numberOfTargetBits) - 1;
    //     emit log_named_uint("mask", mask);

    //     uint256 selectorUint = (bitmap >> 128) & mask;

    //     // when casting from uint256 to bytes4, we need to make sure our 32bits occupy the most significant bits, so
    // shift left to the 32 most significant bits
    //     selectorUint = selectorUint << 224;
    //     emit log_named_uint("selectorUint", selectorUint);

    //     bytes4 selectorBytes4 = bytes4(bytes32(selectorUint));
    //     emit log_named_bytes4("selectorBytes4", selectorBytes4);

    //     return selectorBytes4;
    // }
}
