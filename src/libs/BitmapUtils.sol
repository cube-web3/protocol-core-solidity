// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


library BitmapUtils {

    /// @notice
    function extractBytes16Bitmap(uint256 bitmap) internal pure returns (bytes16 moduleId) {
        assembly {
            // Mask to extract the right-most 16 bytes
            let mask := sub(shl(128, 1), 1)
            moduleId := shl(128, and(bitmap, mask))
        }
    }

    function extractUint32FromBitmap(uint256 bitmap, uint256 location) internal pure returns (uint32 value) {
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location', apply mask, and cast to uint32
            value := and(shr(location, bitmap), mask)
        }
    }

    function extractBytes4FromBitmap(uint256 bitmap, uint256 location) internal pure returns (bytes4 value) {
        assembly {
            // Mask to extract 32 bits
            let mask := sub(shl(32, 1), 1)
            // Shift bitmap right by 'location' and apply mask
            value := and(shr(location, bitmap), mask)
            value := shl(224, value)
        }
    }
    
}