// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { PayloadUtils } from "../../../src/libs/PayloadUtils.sol";
import { SignatureUtils } from "../../../src/libs/SignatureUtils.sol";
import { AddressUtils } from "../../../src/libs/AddressUtils.sol";
import { BitmapUtils } from "../../../src/libs/BitmapUtils.sol";

import { Structs } from "../../../src/common/Structs.sol";

contract UtilsHarness {
    using PayloadUtils for bytes;
    using SignatureUtils for bytes;
    using AddressUtils for address;
    using BitmapUtils for uint256;

    function parseRoutingInfoAndPayload(bytes calldata integrationCalldata)
        external
        pure
        returns (bytes4 moduleSelector, bytes16 moduleId, bytes memory modulePayload, bytes32 originalCalldataDigest)
    {
        return integrationCalldata.parseRoutingInfoAndPayload();
    }

    function extractBytes16Bitmap(uint256 bitmap) external pure returns (bytes16 moduleId) {
        return bitmap.extractBytes16Bitmap();
    }

    function extractUint32FromBitmap(uint256 bitmap, uint8 offset) external pure returns (uint32 value) {
        return bitmap.extractUint32FromBitmap(offset);
    }

    function extractBytes4FromBitmap(uint256 bitmap, uint8 offset) external pure returns (bytes4 value) {
        return bitmap.extractBytes4FromBitmap(offset);
    }

    function parseIntegrationFunctionCallSelector(bytes calldata integrationCalldata)
        external
        pure
        returns (bytes4 selector)
    {
        return integrationCalldata.parseIntegrationFunctionCallSelector();
    }

    function assertIsContract(address target) public view returns (bool) {
        target.assertIsContract();
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
        signature.assertIsValidSignature(digest, signer);
        return true;
    }
}
