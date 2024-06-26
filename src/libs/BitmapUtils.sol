// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title BitmapUtils
/// @notice Library containing utilities to extract values packed into a uint256 Bitmap.
library BitmapUtils {
    /*
        Note: When creating a mask, subtracting by 1 sets all bits to the right as 1s, thus creating
              a mask of 1s for the & operation.

        Eg. Creating a mask for the 4 least significant bits:
        uint8 shift = (uint8(1) << 4)
                    = 16
                    = 0 0 0 1 0 0 0 0
        uint8 mask  = shift - 1
                    = 15
                    = 0 0 0 0 1 1 1 1
    */

    /// @notice Extracts a bytes16 from the right-most (least significant) 128 bits.
    /// @param bitmap The bitmap to extract the bytes16 from
    /// @return moduleId The Module ID retrieved from the bitmap.
    function extractBytes16Bitmap(uint256 bitmap) internal pure returns (bytes16 moduleId) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask to extract the right-most 16 bytes
            let mask := sub(shl(128, 1), 1)
            // apply the mask and shift left to occupy the most significant 16 bytes (256 - 128 = 128)
            moduleId := shl(128, and(bitmap, mask))
        }
    }

    /// @notice Extracts a uint32 from the bitmap.
    /// @param bitmap The bitmap to extract the uint32 from
    /// @param location The offset from the least-significant bit.
    /// @return value The uint32 value extracted from the bitmap.
    function extractUint32FromBitmap(uint256 bitmap, uint8 location) internal pure returns (uint32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location', apply mask, and cast to uint32
            value := and(shr(location, bitmap), mask)
        }
    }

    /// @notice Extracts a bytes4 from the bitmap at the specified location.
    /// @dev Converting to bytes4 from uint32 by shifting left to the most significant bit.
    /// @param bitmap The bitmap to extract the bytes4 from.
    /// @param location The offset from the least-significant bit.
    /// @return value The bytes4 value extracted from the bitmap.
    function extractBytes4FromBitmap(uint256 bitmap, uint8 location) internal pure returns (bytes4 value) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location' and apply mask
            value := and(shr(location, bitmap), mask)
            // shift left to occupy the most significant 4 bytes (256 - 32 = 224)
            value := shl(224, value)
        }
    }
}
