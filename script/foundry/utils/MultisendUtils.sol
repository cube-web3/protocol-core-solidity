// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import "forge-std/console.sol";



abstract contract MultisendUtils is Script {

    // Helper function to encode a single transaction
    function _encodeTransactionForMultisend(
        address to,
        uint256 value,
        bytes memory data
    ) public pure returns (bytes memory) {
        return abi.encodePacked(
            uint8(0), // operation (0 for call)
            to,       // target address
            value,    // value in wei
            uint256(data.length), // length of data
            data     // transaction data
        );
    }
}