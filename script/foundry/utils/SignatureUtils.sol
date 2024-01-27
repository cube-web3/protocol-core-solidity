// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "forge-std/Test.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { ICube3Router } from "../../../src/interfaces/ICube3Router.sol";

abstract contract SignatureUtils is Script {
    using ECDSA for bytes32;

    function _generateRegistrarSignature(
        address router,
        address integration,
        uint256 signingAuthPvtKey
    )
        internal
        view
        returns (bytes memory)
    {
        address integrationSecurityAdmin = ICube3Router(router).getIntegrationAdmin(integration);
        return
            _createSignature(abi.encodePacked(integration, integrationSecurityAdmin, block.chainid), signingAuthPvtKey);
    }

    function _createSignature(
        bytes memory encodedSignatureData,
        uint256 pvtKeyToSignWith
    )
        private
        pure
        returns (bytes memory signature)
    {
        bytes32 signatureHash = keccak256(encodedSignatureData);
        bytes32 ethSignedHash = signatureHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

        signature = abi.encodePacked(r, s, v);

        (, ECDSA.RecoverError error) = ethSignedHash.tryRecover(signature);
        if (error != ECDSA.RecoverError.NoError) {
            revert("No Matchies");
        }
    }
}
