// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";

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
        if (size == 0) revert ProtocolErrors.Cube3Protocol_TargetNotAContract(target);
    }

    function assertIsEOAorConstructorCall(address target) internal view {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        if (size > 0) revert ProtocolErrors.Cube3Protocol_TargetIsContract(target);
    }
}
