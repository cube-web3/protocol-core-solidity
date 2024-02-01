// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract TestEvents {
  event MockModuleCallSucceeded();
  event MockModuleCallSucceededWithArgs(bytes32 arg);
}