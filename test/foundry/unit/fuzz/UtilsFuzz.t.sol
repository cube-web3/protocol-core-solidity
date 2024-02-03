// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "../../../../src/common/Structs.sol";
import { MockRegistry } from "../../../mocks/MockRegistry.t.sol";
import { MockModule } from "../../../mocks/MockModule.t.sol";
import { MockCaller, MockTarget } from "../../../mocks/MockContract.t.sol";

import { UtilsHarness } from "../../harnesses/UtilsHarness.sol";

// TODO: use same as script
import { PayloadCreationUtils } from "../../../libs/PayloadCreationUtils.sol";

contract Utils_Fuzz_Unit_Test is BaseTest {
    using ECDSA for bytes32;

    UtilsHarness utilsHarness;

    function setUp() public {
        utilsHarness = new UtilsHarness();
    }

    /*//////////////////////////////////////////////////////////////
        PAYLOAD UTILS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_SucceedsWhen_PayloadDataIsValid(uint256 calldataSize, uint256 modulePayloadSize) public {
        calldataSize = bound(calldataSize, 32, 4096);
        modulePayloadSize = bound(modulePayloadSize, 32, 4096);
        vm.assume(calldataSize % 32 == 0);

        // create arbitrary length calldata and attach the module payload + bitmap,
        // we dont care that these are empty bytes
        bytes memory emptyBytes = new bytes(PayloadCreationUtils.SIGNATURE_MODULE_PAYLOAD_SIZE);
        bytes memory mockCalldata = _getRandomBytes(calldataSize);
        bytes memory mockCalldataWithEmptyPayload = abi.encode(mockCalldata, emptyBytes);

        // The 64 bytes accounts for What? // TODO
        bytes memory mockSlicedCalldata = PayloadCreationUtils.sliceBytes(
            mockCalldataWithEmptyPayload,
            0,
            mockCalldataWithEmptyPayload.length - PayloadCreationUtils.SIGNATURE_MODULE_PAYLOAD_SIZE - 64
        );
        bytes32 mockCalldataDigest = keccak256(mockSlicedCalldata);

        bytes memory mockModulePayload = _getRandomBytes(modulePayloadSize);

        bytes16 mockModuleID = bytes16(bytes32(keccak256(abi.encode(calldataSize))));
        bytes4 moduleSelector = bytes4(bytes32(keccak256(abi.encode(modulePayloadSize))));
        uint32 modulePadding = PayloadCreationUtils.calculateRequiredModulePayloadPadding(modulePayloadSize);

        // create the bitmap containing the routing data
        uint256 routingBitmap = PayloadCreationUtils.createRoutingFooterBitmap(
            mockModuleID, moduleSelector, uint32(mockModulePayload.length), modulePadding
        );

        // pad the module payload to the next full word
        bytes memory packedModulePayload =
            PayloadCreationUtils.createPaddedModulePayload(mockModulePayload, modulePadding);

        // assertEq(mockCube3Payload.length, PayloadCreationUtils.SIGNATURE_MODULE_PAYLOAD_SIZE, "payload size
        // mismatch");
        // emit log_named_bytes("mockCube3Payload", mockCube3Payload);

        // combine the module payload and the routing bitmap
        bytes memory mockCube3Payload = abi.encodePacked(packedModulePayload, routingBitmap);

        // create the mock function calldata, where the payload is the final arg
        bytes memory combined = abi.encodePacked(mockCalldata, mockCube3Payload);

        // perform the test
        (
            bytes4 derivedSelector,
            bytes16 derivedModuleID,
            bytes memory derivedModulePayload,
            bytes32 derivedOriginalCalldataDigest
        ) = utilsHarness.extractPayloadDataFromCalldata(combined);

        assertEq(derivedSelector, moduleSelector, "selector not matching");
        assertEq(derivedModuleID, mockModuleID, "module id not matching");
        assertEq(keccak256(derivedModulePayload), keccak256(mockModulePayload), "module payload not matching");
        assertEq(mockCalldataDigest, derivedOriginalCalldataDigest, "digest not matching");
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
        bytes4 derivedSelector = utilsHarness.extractCalledIntegrationFunctionSelector(mockCalldata);
        assertEq(derivedSelector, selector, "selector not matching");
    }

    // fails when the target contract is an EOA
    function testFuzz_RevertsWhen_TargetIsEOA(uint256 addressSeed) public {
        address target = address(uint160(uint256(keccak256(abi.encodePacked(addressSeed)))));
        vm.expectRevert(bytes("TODO: Not a contract"));
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
        locationSeed = bound(locationSeed, 0, 255);
        retrievalSeed = bound(retrievalSeed, 0, 255);
        vm.assume(locationSeed != retrievalSeed);
        vm.assume(locationSeed % 32 == 0);
        vm.assume(retrievalSeed % 32 == 0);
        valueSeed = bound(valueSeed, 1, type(uint32).max);
        uint32 value = uint32(valueSeed);
        uint8 location = uint8(locationSeed);
        uint8 retrieval = uint8(retrievalSeed);

        uint256 bitmap = uint256(0);
        bitmap = PayloadCreationUtils.addUint32ToBitmap(bitmap, value, location);
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

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _createPayloadSignature(encodedSignatureData, signerPvtKey);

        bytes32 digest = keccak256(encodedSignatureData);

        vm.expectRevert(bytes("CR12: invalid signer"));
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

        vm.expectRevert(bytes("TODO: InvalidSignature"));
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

        vm.expectRevert(bytes("TODO: InvalidSigLength"));
        utilsHarness.assertIsValidSignature(signature, digest, signer);
    }

    // fails when different digest (encoded data) is used
    function testFuzz_RevertsWhen_IncorrectDigestUsed(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _createPayloadSignature(encodedSignatureData, signerPvtKey);

        bytes32 altDigest = keccak256(_getRandomBytes(dataLength + 1));

        vm.expectRevert(bytes("CR12: invalid signer"));
        utilsHarness.assertIsValidSignature(signature, altDigest, _randomAddress());
    }

    // fails when different signature is used
    function testFuzz_RevertsWhen_DifferentSignatureUsed(uint256 dataLength, uint256 signerPvtKey) public {
        signerPvtKey = bound(signerPvtKey, 1, type(uint128).max);
        dataLength = bound(dataLength, 1, 4096);

        address signer = vm.addr(signerPvtKey);
        bytes memory encodedSignatureData = _getRandomBytes(dataLength);
        bytes memory signature = _createPayloadSignature(encodedSignatureData, signerPvtKey);

        bytes memory altEncodedSignatureData = _getRandomBytes(dataLength + 1);
        bytes memory altSignature = _createPayloadSignature(altEncodedSignatureData, signerPvtKey);

        bytes32 digest = keccak256(encodedSignatureData);

        vm.expectRevert(bytes("CR12: invalid signer"));
        utilsHarness.assertIsValidSignature(altSignature, digest, signer);
    }
}
