// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";

/// @title AddressUtils
/// @notice Contains utility functions for checking what type of accounts an address belongs to.
library AddressUtils {
    /// @notice Checks if an account is a contract.
    /// @dev Ensures the target address is a contract. This is done by checking the length
    /// of the bytecode stored at that address. Reverts if the address is not a contract.
    ///@param target Address to check the bytecode size.
    function assertIsContract(address target) internal view {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        if (size == 0) revert ProtocolErrors.Cube3Protocol_TargetNotAContract(target);
    }

    /// @notice Checks if an account is an EOA or a contract under construction.
    /// @dev Ensures the target address is an EOA, or a contract under construction. Reverts
    /// if the codesize check is failed.
    /// @param target Address to check the bytecode size.
    function assertIsEOAorConstructorCall(address target) internal view {
        uint256 size;
        assembly {
            size := extcodesize(target)
        }
        if (size > 0) revert ProtocolErrors.Cube3Protocol_TargetIsContract(target);
    }
}
