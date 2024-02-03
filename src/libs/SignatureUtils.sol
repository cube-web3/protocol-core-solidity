// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library SignatureUtils {
    using ECDSA for bytes32;

    // TODO: dev
    function assertIsValidSignature(bytes calldata signature, bytes32 digest, address signer) internal pure {
        bytes32 ethSignedHash = digest.toEthSignedMessageHash();
        // `tryRecover` returns ECDSA.RecoverError error as the second return value, but we don't need
        // to evaluate as any error returned will return address(0) as the first return value
        (address payloadSigner, ECDSA.RecoverError ecdsaError) = ethSignedHash.tryRecover(signature); // 3k gas
        if (ecdsaError == ECDSA.RecoverError.InvalidSignature) {
            revert("TODO: InvalidSignature");
        } else if (ecdsaError == ECDSA.RecoverError.InvalidSignatureLength) {
            revert("TODO: InvalidSigLength");
        }
        require(payloadSigner != address(0), "CR11: zero signer");
        require(payloadSigner == signer, "CR12: invalid signer");
    }
}
