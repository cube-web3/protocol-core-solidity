// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { BaseTest } from "@test/foundry/BaseTest.t.sol";
import { Structs } from "@src/common/Structs.sol";
import { MockRegistry } from "@test/mocks/MockRegistry.t.sol";
import { MockModule } from "@test/mocks/MockModule.t.sol";
import { MockCaller, MockTarget } from "@test/mocks/MockContract.t.sol";

import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { UtilsHarness } from "@test/foundry/harnesses/UtilsHarness.sol";

// TODO: use same as script
import { PayloadCreationUtils } from "@test/libs/PayloadCreationUtils.sol";

contract Utils_Fuzz_Unit_Test is BaseTest {
    using ECDSA for bytes32;

    UtilsHarness utilsHarness;

    function setUp() public override {
        utilsHarness = new UtilsHarness();
    }

    /*//////////////////////////////////////////////////////////////
        PAYLOAD UTILS
    //////////////////////////////////////////////////////////////*/

    event log_named_bytes16(string name, bytes16 value);

    function testFuzz_SucceedsWhen_PayloadDataIsValid(
        uint256 calldataSize,
        uint256 idSeed,
        uint256 nonce
    )
        public
    {
        calldataSize = bound(calldataSize, 32, 256);
        idSeed = bound(idSeed, 1, type(uint256).max);
        vm.assume(calldataSize % 32 == 0);

        bool shouldTrackNonce = nonce % 2 == 0;

        bytes16 mockModuleId = bytes16(bytes32(idSeed));
        emit log_named_bytes16("module id", mockModuleId);

        bytes4 mockSelector = bytes4(keccak256(abi.encode(idSeed)));
        emit log_named_bytes4("mockSelector", mockSelector);

        // mock the calldata for the integration function call (without the CUBE3 payload), which needs to fit into
        // full words to match abi encoded data
        bytes memory mockSlicedCalldata = _getRandomBytes(calldataSize);

        // create the digest of the "original" function call's selector + args
        bytes32 calldataDigest = keccak256(mockSlicedCalldata);
        emit log_named_bytes32("calldataDigest", calldataDigest);

        // bytes memory signature = _createPayloadSignature(signatureData, pvtKey);
        bytes memory signature = _getRandomBytes(65);

        // create the module payload
        (bytes memory modulePayloadWithPadding, uint32 padding) = _encodeModulePayloadAndPadToNextFullWord(
            shouldTrackNonce, // whether to track the nonce
            block.timestamp + 1 hours,
            shouldTrackNonce ? nonce + 1 : 0,
            signature
        );

        emit log_named_uint32("length", uint32(modulePayloadWithPadding.length));
        emit log_named_uint32("padding", padding);

        // create the routing bitmap
        uint256 routingBitmap =
            _createRoutingFooterBitmap(mockModuleId, mockSelector, uint32(modulePayloadWithPadding.length), padding);
        emit log_named_uint("routing bitmap", routingBitmap);

        // normal abi.encoding adds the length as the first word of modulePayloadWithPadding, so we need to simulate it
        bytes memory combined = abi.encodePacked(
            mockSlicedCalldata, uint256(modulePayloadWithPadding.length), modulePayloadWithPadding, routingBitmap
        );

        // perform the test
        (
            bytes4 derivedSelector,
            bytes16 derivedModuleID,
            bytes memory derivedModulePayload,
            bytes32 derivedOriginalCalldataDigest
        ) = utilsHarness.parseRoutingInfoAndPayload(combined);

        // confirm the data that's parsed is correct
        assertEq(derivedSelector, mockSelector, "selector not matching");
        assertEq(derivedModuleID, mockModuleId, "module id not matching");

        // the actual module payload has the padding removed from the module payload
        assertEq(
            keccak256(derivedModulePayload),
            keccak256(_removeBytesFromEnd(modulePayloadWithPadding, padding)),
            "module payload not matching"
        );
        assertEq(calldataDigest, derivedOriginalCalldataDigest, "digest not matching");
    }

    function testFuzz_SucceedsWhen_ExtractingIntegrationFunctionSelector(
        uint256 selectorSeed,
        uint256 bytesSize
    )
        public
    {
        bytesSize = bound(bytesSize, 0, 4096);
        bytes4 selector = bytes4(bytes32(keccak256(abi.encodePacked(selectorSeed))));
        bytes memory mockBytes = _getRandomBytes(bytesSize);

        bytes memory mockCalldata = abi.encodeWithSelector(selector, mockBytes);
        bytes4 derivedSelector = utilsHarness.parseIntegrationFunctionCallSelector(mockCalldata);
        assertEq(derivedSelector, selector, "selector not matching");
    }

    // fails when the target contract is an EOA
    function testFuzz_RevertsWhen_TargetIsEOA(uint256 addressSeed) public {
        address target = address(uint160(uint256(keccak256(abi.encodePacked(addressSeed)))));
        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Protocol_TargetNotAContract.selector, target));
        utilsHarness.assertIsContract(target);
    }

    /*//////////////////////////////////////////////////////////////
         BITMAP UTILS
    //////////////////////////////////////////////////////////////*/

    // succeeds when bytes16 is extracted from the least-significant 16 bits
    /// @dev The moduleId always occupies the right-most 16 bytes of the bitmap, so
    ///      the offset is always 0.
    function testFuzz_SucceedsWhen_Bytes16ExtractFromLeastSignficantBits(uint256 bytes16seed) public {
        uint256 bitmap = uint256(0);
        uint8 offset = uint8(0);
        bytes16 mockId = bytes16(bytes32(keccak256(abi.encodePacked(bytes16seed))));

        // add the module ID in the right-most 16 bytes
        bitmap = PayloadCreationUtils.addBytes16ToBitmap(bitmap, mockId, offset);
        bytes16 derivedId = utilsHarness.extractBytes16Bitmap(bitmap);
        assertEq(derivedId, mockId, "id not matching");
    }

    // TODO: create invariant for this
    // succeeds when uint32 is extracted from the bitmap at the correct location
    function testFuzz_SucceedsWhen_Uint32ExtractedFromAnyLocationInBitmap(
        uint256 valueSeed,
        uint256 locationSeed
    )
        public
    {
        locationSeed = bound(locationSeed, 0, 255);
        vm.assume(locationSeed % 32 == 0);
        valueSeed = bound(valueSeed, 0, type(uint32).max);
        uint32 value = uint32(valueSeed);
        uint8 location = uint8(locationSeed);

        uint256 bitmap = uint256(0);
        bitmap = PayloadCreationUtils.addUint32ToBitmap(bitmap, value, location);

        uint32 derivedValue = utilsHarness.extractUint32FromBitmap(bitmap, uint8(location));
        assertEq(derivedValue, value, "value not matching");
    }

    // succeeds extracting a bytes4 from the bitmap at the correct location
    function testFuzz_SucceedsWhen_ExtractingBytes4FromBitmapAtCorrectLocation(
        uint256 bytes4seed,
        uint256 locationSeed
    )
        public
    {
        locationSeed = bound(locationSeed, 0, 255);
        vm.assume(locationSeed % 32 == 0);

        bytes4 selector = bytes4(bytes32(keccak256(abi.encodePacked(bytes4seed))));
        uint8 location = uint8(locationSeed);

        uint256 bitmap = uint256(0);
        uint32 castBytes4 = uint32(selector);
        bitmap = PayloadCreationUtils.addUint32ToBitmap(bitmap, castBytes4, location);

        bytes4 derivedSelector = utilsHarness.extractBytes4FromBitmap(bitmap, location);
        assertEq(derivedSelector, selector, "selector not matching");
    }

    // fails when attempting to extract uint32 from the wrong location in the bitmap
    function testFuzz_RevertsWhen_Uint32ExtractedFromWrongLocationInBitmap(
        uint256 valueSeed,
        uint256 locationSeed,
        uint256 retrievalSeed
    )
        public
    {
        locationSeed = bound(locationSeed, 0, 255 - 32);
        retrievalSeed = bound(retrievalSeed, 32, 255);
        locationSeed = _toMultipleOf32(locationSeed);
        retrievalSeed = _toMultipleOf32(retrievalSeed);

        valueSeed = bound(valueSeed, 1, type(uint32).max);
        uint32 value = uint32(valueSeed);
        uint8 location = uint8(locationSeed);
        uint8 retrieval = uint8(retrievalSeed);
        vm.assume(location != retrieval);

        uint256 bitmap = uint256(0);
        bitmap = PayloadCreationUtils.addUint32ToBitmap(bitmap, value, location);
        emit log_named_uint("bitmap", bitmap);
        uint32 derivedValue = utilsHarness.extractUint32FromBitmap(bitmap, retrieval);
        assertNotEq(derivedValue, value, "value not matching");
    }

    /*//////////////////////////////////////////////////////////////
         SIGNATURE UTILS
    //////////////////////////////////////////////////////////////*/

    // succeeds when recovering a valid signature from the signer
    function testFuzz_SucceedsWhen_SignerIsRecovered(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _createPayloadSignature(encodedSignatureData, signerPvtKey);

        bytes32 digest = keccak256(encodedSignatureData);
        assertTrue(utilsHarness.assertIsValidSignature(signature, digest, signer));
    }

    // fails when recoverign a signature not matching the signer
    function testFuzz_RevertsWhen_RecoveredSignerNotMatching(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _createPayloadSignature(encodedSignatureData, signerPvtKey);

        bytes32 digest = keccak256(encodedSignatureData);

        vm.expectRevert(ProtocolErrors.Cube3SignatureUtils_InvalidSigner.selector);
        utilsHarness.assertIsValidSignature(signature, digest, _randomAddress());
    }

    // fails when signature provided is empty bytes
    function testFuzz_RevertsWhen_SignatureIsEmptyBytes(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = new bytes(65);

        bytes32 digest = keccak256(encodedSignatureData);

        vm.expectRevert(ECDSA.ECDSAInvalidSignature.selector);
        utilsHarness.assertIsValidSignature(signature, digest, signer);
    }

    // fails when signature is wrong length
    /// @dev ECDSA.tryRecover returns address(0) when the signature is the incorrect length
    function testFuzz_RevertsWhen_SignatureIsIncorrectLength(
        uint256 dataLength,
        uint256 signerPvtKey,
        uint256 signatureLength
    )
        public
    {
        signatureLength = bound(signatureLength, 1, type(uint8).max);
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        vm.assume(signatureLength != 65);
        dataLength = bound(dataLength, 1, 4096);

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _getRandomBytes(signatureLength);

        bytes32 digest = keccak256(encodedSignatureData);

        vm.expectRevert(abi.encodeWithSelector(ECDSA.ECDSAInvalidSignatureLength.selector, signatureLength));
        utilsHarness.assertIsValidSignature(signature, digest, signer);
    }

    // fails when different digest (encoded data) is used
    function testFuzz_RevertsWhen_IncorrectDigestUsed(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _createPayloadSignature(encodedSignatureData, signerPvtKey);

        bytes32 altDigest = keccak256(_getRandomBytes(dataLength + 1));

        vm.expectRevert(ProtocolErrors.Cube3SignatureUtils_InvalidSigner.selector);
        utilsHarness.assertIsValidSignature(signature, altDigest, _randomAddress());
    }

    // fails when different signature is used
    function testFuzz_RevertsWhen_DifferentSignatureUsed(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory altEncodedSignatureData = _getRandomBytes(dataLength + 1);
        bytes memory altSignature = _createPayloadSignature(altEncodedSignatureData, signerPvtKey);

        bytes32 digest = keccak256(encodedSignatureData);

        vm.expectRevert(ProtocolErrors.Cube3SignatureUtils_InvalidSigner.selector);
        utilsHarness.assertIsValidSignature(altSignature, digest, signer);
    }

    // Removes `lengthToRemove` bytes from the end of a `bytes memory data`
    function _removeBytesFromEnd(bytes memory data, uint256 lengthToRemove) internal pure returns (bytes memory) {
        require(lengthToRemove <= data.length, "Cannot remove more bytes than the data contains");

        uint256 newLength = data.length - lengthToRemove;
        bytes memory newData = new bytes(newLength);

        for (uint256 i = 0; i < newLength; i++) {
            newData[i] = data[i];
        }

        return newData;
    }

    function _toMultipleOf32(uint256 value) internal pure returns (uint256) {
        if (value % 32 == 0) {
            return value; // Already a multiple of 32
        } else {
            return ((value / 32) + 1) * 32;
        }
    }
}
