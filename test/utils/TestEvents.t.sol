// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

/// @notice Custom events used for testing.
abstract contract TestEvents {
  event MockModuleCallSucceeded();
  event MockModuleCallSucceededWithArgs(bytes32 arg);
  event BalanceUpdated(address indexed account, uint256 newBalance);
  event CustomDeprecation();

  event log_named_bytes4(string name, bytes4 value);
  event log_named_uint32(string name, uint32 value);
}