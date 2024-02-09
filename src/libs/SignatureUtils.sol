// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ProtocolErrors } from "./ProtocolErrors.sol";

library SignatureUtils {

    // TODO: dev
    function assertIsValidSignature(bytes memory signature, bytes32 digest, address signer) internal pure {
        // generate a EIP-191 comaptible eth signed message hash
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(digest);

        // Recover the signer from the signature using the eth signed message hash.  Will throw
        // an ECDSA.RecoverError if the signature is invalid.
        address recoveredSigner = ECDSA.recover(ethSignedHash, signature); // 3k gas

        // TODO: test this
        // Checks: the recovered signer is not the zero address.
        if (recoveredSigner == address(0)) {
            revert ProtocolErrors.Cube3SignatureUtils_SignerZeroAddress();
        }

        // Checks: the signer recoverd matches the expected signer.
        if (recoveredSigner != signer) {
            revert ProtocolErrors.Cube3SignatureUtils_InvalidSigner();
        }
    }
}
