// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { PayloadUtils } from "@src/libs/PayloadUtils.sol";
import { SignatureUtils } from "@src/libs/SignatureUtils.sol";
import { AddressUtils } from "@src/libs/AddressUtils.sol";
import { BitmapUtils } from "@src/libs/BitmapUtils.sol";

import { Structs } from "@src/common/Structs.sol";

/// note: For the purposes of coverage, we utilze the <library>.<function>(...args) approach, rather than
/// "using <library> for <type>" with the target passed implicitly as the first arg, which coverage doesn't recognize.

contract UtilsHarness {
    using PayloadUtils for bytes;
    using SignatureUtils for bytes;
    using AddressUtils for address;
    using BitmapUtils for uint256;

    function parseRoutingInfoAndPayload(bytes calldata integrationCalldata)
        external
        pure
        returns (
            bytes4 moduleSelector,
            bytes16 moduleId,
            bytes memory modulePayload,
            bytes32 originalCalldataDigest
        )
    {
        return PayloadUtils.parseRoutingInfoAndPayload(integrationCalldata);
    }

    function extractBytes16Bitmap(uint256 bitmap) external pure returns (bytes16 moduleId) {
        return BitmapUtils.extractBytes16Bitmap(bitmap);
    }

    function extractUint32FromBitmap(uint256 bitmap, uint8 offset) external pure returns (uint32 value) {
        return BitmapUtils.extractUint32FromBitmap(bitmap, offset);
    }

    function extractBytes4FromBitmap(uint256 bitmap, uint8 offset) external pure returns (bytes4 value) {
        return BitmapUtils.extractBytes4FromBitmap(bitmap, offset);
    }

    function parseIntegrationFunctionCallSelector(bytes calldata integrationCalldata)
        external
        pure
        returns (bytes4 selector)
    {
        return PayloadUtils.parseIntegrationFunctionCallSelector(integrationCalldata);
    }

    function assertIsContract(address target) public view returns (bool) {
        AddressUtils.assertIsContract(target);
        return true;
    }

    function assertIsEOAorConstructorCall(address target) public view returns (bool) {
        AddressUtils.assertIsEOAorConstructorCall(target);
        return true;
    }

    function assertIsValidSignature(
        bytes calldata signature,
        bytes32 digest,
        address signer
    )
        external
        pure
        returns (bool)
    {
        SignatureUtils.assertIsValidSignature(signature, digest, signer);
        return true;
    }
}
