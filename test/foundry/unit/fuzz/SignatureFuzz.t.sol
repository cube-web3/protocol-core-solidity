// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "../../../../src/common/Structs.sol";

import { UtilsHarness } from "../../harnesses/UtilsHarness.sol";

import {PayloadCreationUtils} from "../../../libs/PayloadCreationUtils.sol";

contract Signature_Fuzz_Unit_Test is BaseTest {
    using ECDSA for bytes32;

    UtilsHarness utilsHarness;

    function setUp() public {
        utilsHarness = new UtilsHarness();
    }

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
    function testFuzz_RevertsWhen_SignatureIsIncorrectLength(uint256 dataLength, uint256 signerPvtKey, uint256 signatureLength) public {
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

     bytes32 altDigest = keccak256(_getRandomBytes(dataLength+1));

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

     bytes memory altEncodedSignatureData = _getRandomBytes(dataLength+1);
     bytes memory altSignature = _createPayloadSignature(altEncodedSignatureData, signerPvtKey);


     bytes32 digest = keccak256(encodedSignatureData);

     vm.expectRevert(bytes("CR12: invalid signer"));
     utilsHarness.assertIsValidSignature(altSignature, digest, signer);
    }




}