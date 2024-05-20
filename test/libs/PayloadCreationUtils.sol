// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {Structs} from "@src/common/Structs.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";

library PayloadCreationUtils {
    address private constant VM_ADDRESS = address(bytes20(uint160(uint256(keccak256("hevm cheat code")))));
    Vm private constant vm = Vm(VM_ADDRESS);

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
       - moduleSelector (bytes4)
       - modulePayloadLength (uint32)
       - modulePaddingUsed (uint32)
     - create the packedModulePayload by concatenating the modulePayload and the padding
     - combining packedModulePayload + routingBitmap by packing them to create the cube3Payload
    */

    event log_bitmap(uint256 bitmap);
    event log_payload(bytes p);
    event log_uint(uint256 l);
    event log_bytes32(bytes32 b);
    event log_named_uint(string name, uint256 l);
    event log_named_bytes32(string name, bytes32 b);
    event log_named_address(string name, address a);
    event log_named_bytes(string name, bytes b);
    /// @dev The CUBE3 payload combines the module payload and the routing bitmap.
    function createCube3PayloadForSignatureModule(
        address integration,
        address caller,
        uint256 pvtKeyToSignWith,
        uint256 expirationWindow,
        bool trackNonce,
        Cube3SignatureModule signatureModule,
        Structs.TopLevelCallComponents memory topLevelCallComponents
    ) internal returns (bytes memory) {
        uint256 expirationTimestamp = 1715545464; // block.timestamp + expirationWindow;
        uint256 userNonce = trackNonce ? signatureModule.integrationUserNonce(integration, caller) + 1 : 0;
        emit log_named_uint("expectedUserNonce", userNonce);

        bytes4 sigSelector = Cube3SignatureModule.validateSignature.selector;
        emit log_named_bytes4("sigSelector", sigSelector);
        emit log_named_uint("expirationTimestamp", expirationTimestamp);
        // create the signature using the signers private key
        bytes memory encodedDataForSigning = abi.encode(
            11155111, //block.chainid, // chain id
            topLevelCallComponents,
            address(signatureModule), // module contract address
            sigSelector, // the module fn's signature
            userNonce,
            expirationTimestamp // expiration
        );

        emit log_named_bytes("encodedDataForSigning", encodedDataForSigning);
        bytes memory signature = signPayloadData(encodedDataForSigning, pvtKeyToSignWith);
        emit log_named_bytes("signature", signature);
        emit log_uint(signature.length);

        // create the signature module payload and pad it to the next full word
        bytes memory encodedModulePayloadData = abi.encodePacked(expirationTimestamp, trackNonce, userNonce, signature);
        emit log_payload(encodedModulePayloadData);

        uint32 paddingNeeded = uint32(calculateRequiredModulePayloadPadding(encodedModulePayloadData.length));
        emit log_named_uint("paddingNeeded", paddingNeeded);
        bytes memory modulePayloadWithPadding = createPaddedModulePayload(encodedModulePayloadData, paddingNeeded);
        emit log_payload(modulePayloadWithPadding);
        emit log_uint(paddingNeeded);

        // creating the routing bitmap
        uint256 bitmap = uint256(0);

        // add the module ID in the right-most 16 bytes
        bitmap = bitmap + uint256(uint128(signatureModule.moduleId()));

        // add the module selector in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(Cube3SignatureModule.validateSignature.selector)) << 128);

        // add the module payload length in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(modulePayloadWithPadding.length)) << 160);

        // add the cube payload length in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(paddingNeeded)) << 192);

        // emit log_bytes32(bytes32(signatureModule.moduleId()));
        emit log_bitmap(bitmap);
        // combine and return them.
        return abi.encodePacked(modulePayloadWithPadding, bitmap);
    }

    function signPayloadData(
        bytes memory encodedSignatureData,
        uint256 pvtKeyToSignWith
    ) internal pure returns (bytes memory signature) {
        bytes32 signatureHash = keccak256(encodedSignatureData);

        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(signatureHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

        signature = abi.encodePacked(r, s, v);

        require(signature.length == 65, "invalid signature length");

        address signedHashAddress = ECDSA.recover(ethSignedHash, signature);

        require(signedHashAddress == vm.addr(pvtKeyToSignWith), "signers dont match");
    }

    function calculateRequiredModulePayloadPadding(uint256 modulePayloadLength) internal pure returns (uint32) {
        // calculate the padding needed to fill it to the final word
        return uint32((32 - (modulePayloadLength % 32)) % 32);
    }

    function createPaddedModulePayload(
        bytes memory modulePayload,
        uint32 modulePaddingSize
    ) internal pure returns (bytes memory) {
        // pad the module payload to the next word
        bytes memory payloadWithPadding = new bytes(modulePayload.length + modulePaddingSize);

        // only fill the data up until the payload lenght, the rest will be 0s (matching the paddingLength)
        for (uint256 i = 0; i < modulePayload.length; ) {
            payloadWithPadding[i] = modulePayload[i];
            unchecked {
                ++i;
            }
        }

        return payloadWithPadding;
    }

    function packageTopLevelCallComponents(
        address caller,
        address integration,
        uint256 msgValue,
        bytes memory integrationCalldataWithEmptyPayload,
        uint256 expectedPayloadSize
    ) internal pure returns (Structs.TopLevelCallComponents memory) {
        // remove the payload so we can create a hash of the calldata without the payload,
        // note: because payload is type bytes, the slicedCalldata may contain some data about the payload,
        // eg. the offset to the payload, and the length of the payload, but this will be the case when it's
        // reproduced on chain.  For all intents and purposes, the empty bytes payload is structurally identical
        // to the payload populated with the correct data. Subtracting 64 accounts for the routing bitmap and the
        // 32 bytes (uint256) that's added to the front of the module payload by the ABI encoding.
        bytes memory slicedCalldata = sliceBytes(
            integrationCalldataWithEmptyPayload,
            0,
            integrationCalldataWithEmptyPayload.length - expectedPayloadSize - 64
        );

        bytes32 calldataDigest = keccak256(slicedCalldata);

        return Structs.TopLevelCallComponents(caller, integration, msgValue, calldataDigest);
    }

    function createRoutingFooterBitmap(
        bytes16 id,
        bytes4 moduleSelector,
        uint32 paddedModulePayloadLength,
        uint32 modulePadding
    ) internal pure returns (uint256) {
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
        bitmap = bitmap + (uint256(uint32(paddedModulePayloadLength)) << 160);

        // add the cube payload length in the next 4 bytes
        bitmap = bitmap + (uint256(uint32(modulePadding)) << 192);

        /*
        // add the module ID in the right-most 16 bytes
        // bitmap = bitmap + uint256(uint128(id));
        bitmap = addBytes16ToBitmap(bitmap, id, 0);

        // add the module selector in the next 4 bytes
        // bitmap = bitmap + (uint256(uint32(moduleSelector)) << 128);
        bitmap = addUint32ToBitmap(bitmap, uint32(moduleSelector), 128);

        // add the module payload length in the next 4 bytes
        // bitmap = bitmap + (uint256(uint32(modulePayloadLength)) << 160);
        bitmap = addUint32ToBitmap(bitmap, uint32(paddedModulePayloadLength), 160);

        // add the cube payload length in the next 4 bytes
        // bitmap = bitmap + (uint256(uint32(modulePadding)) << 192);
        bitmap = addUint32ToBitmap(bitmap, uint32(modulePadding), 192);
        */
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

    function addBytes16ToBitmap(uint256 bitmap, bytes16 id, uint8 offset) public pure returns (uint256) {
        return bitmap + uint256(uint128(id));
    }

    function addUint32ToBitmap(uint256 bitmap, uint32 value, uint8 offset) public pure returns (uint256) {
        return (bitmap + uint256(value)) << offset;
    }

    function sliceBytes(bytes memory _bytes, uint256 start, uint256 end) public pure returns (bytes memory) {
        require(_bytes.length >= end, "Slice end too high");

        bytes memory tempBytes = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            tempBytes[i] = _bytes[i + start];
        }
        return tempBytes;
    }

    function createRegistrarSignature(
        address integrationAdmin,
        address integration,
        uint256 signingAuthPvtKey
    ) internal view returns (bytes memory) {
        return signPayloadData(abi.encodePacked(integration, integrationAdmin, block.chainid), signingAuthPvtKey);
    }
}
