// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ProtocolErrors } from "./ProtocolErrors.sol";

library SignatureUtils {
    using ECDSA for bytes32;

    // TODO: dev
    function assertIsValidSignature(bytes memory signature, bytes32 digest, address signer) internal pure {
        // generate a EIP-191 comaptible eth signed message hash
        bytes32 ethSignedHash = digest.toEthSignedMessageHash();

        // Recover the signer from the signature using the eth signed message hash.
        (address recoveredSigner, ECDSA.RecoverError ecdsaError) = ethSignedHash.tryRecover(signature); // 3k gas

        // Checks: for no errors during the recovery process.
        if (ecdsaError == ECDSA.RecoverError.InvalidSignature) {
            revert ProtocolErrors.Cube3SignatureUtils_InvalidSignature();
        } else if (ecdsaError == ECDSA.RecoverError.InvalidSignatureLength) {
            revert ProtocolErrors.Cube3SignatureUtils_InvalidSignatureLength();
        }

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
