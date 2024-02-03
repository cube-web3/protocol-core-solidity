// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library AddressUtils {
    /**
     * @dev Ensures the target address is a contract. This is done by checking the length
     *      of the bytecode stored at that address. Note: This function will be used to complete
     *      registration, which cannot take place during the contract's deployment, therefore bytecode
     *      length is expected to be non-zero.
     *
     * @param target Address to check the bytecode size.
     */
    function assertIsContract(address target) internal view {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        if (size == 0) revert("TODO: Not a contract");
    }
}
