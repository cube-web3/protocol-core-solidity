// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title ProtocolConstants
/// @notice Defines unique return values for Protocol actions to be stored in the contract's bytecode.
abstract contract ProtocolConstants {
    /// @notice Returned by a module when the module successfuly executes its internal logic.
    bytes32 public constant MODULE_CALL_SUCCEEDED = keccak256("CUBE3_MODULE_CALL_SUCCEEDED");

    /// @notice Returned by the router when the pre-registration of the integration is successful.
    bytes32 public constant PRE_REGISTRATION_SUCCEEDED = keccak256("CUBE3_PRE_REGISTRATION_SUCCEEDED");

    /// @notice Returned by a module when the module's internal logic execution fails.
    bytes32 public constant MODULE_CALL_FAILED = keccak256("CUBE3_MODULE_CALL_FAILED");

    /// @notice Returned by the router if the module call succeeds, the integration is not registered, the protocol is
    /// paused, or
    // the function is not protected.
    bytes32 public constant PROCEED_WITH_CALL = keccak256("CUBE3_PROCEED_WITH_CALL");
}
