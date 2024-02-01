// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ModuleBase} from "../../src/modules/ModuleBase.sol";

import { TestEvents } from "../utils/TestEvents.t.sol";

contract MockModule is ModuleBase, TestEvents {

 bytes32 constant public SUCCESSFUL_RETURN = keccak256("SUCCESSFUL_RETURN");

 bool public preventDeprecation = false;

 constructor(address mockRouter, string memory version, uint256 payloadSize) ModuleBase(mockRouter, version, payloadSize) {}

   function updatePreventDeprecation(bool shouldPreventDeprecation) public {
      preventDeprecation = shouldPreventDeprecation;
   }

 // TODO: test payable
 function privilegedFunctionWithArgs(bytes32 arg) external onlyCube3Router returns(bytes32) {
    emit MockModuleCallSucceededWithArgs(arg);
    return arg;
 }

 function privilegedFunction() external onlyCube3Router returns(bytes32) {
    emit MockModuleCallSucceeded();
    return SUCCESSFUL_RETURN;
 }

 function privilegedFunctionThatReverts() external onlyCube3Router {
  revert("FAILED");
 }

 function deprecate() external override returns(bool, string memory) {
   if (preventDeprecation) {
      return(false, "");
   }

   return (true, moduleVersion);
 }

}