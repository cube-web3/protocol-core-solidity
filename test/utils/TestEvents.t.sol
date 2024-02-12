// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

abstract contract TestEvents {
  event MockModuleCallSucceeded();
  event MockModuleCallSucceededWithArgs(bytes32 arg);
  event BalanceUpdated(address indexed account, uint256 newBalance);
}