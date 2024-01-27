// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {BaseTest} from "../../BaseTest.t.sol";

import {RouterStorageHarness} from "../../harnesses/RouterStorageHarness.sol";

contract RouterStorage_Fuzz_Unit_Test is BaseTest {

 function setUp() public {
  // BaseTest.setUp();
  initProtocol();
 }

 // Setting the protocol config succeeds and emits the correct event
 function testFuzz_SucceedsWhen_ProtocolConfigIsSet(uint256 addressSeed, uint256 flagValue) public {
  addressSeed = bound(addressSeed, 1, 1 + addressSeed/2);
  address registry = vm.addr(addressSeed);
  bool flag = flagValue % 2 == 0;

  // set the config
  vm.expectEmit(true,true,true,true);
  emit ProtocolConfigUpdated(registry, flag);
  routerStorageHarness.setProtocolConfig(registry, flag);

  // check the config values
  assertEq(registry, routerStorageHarness.getProtocolConfig().registry, "registry mismatch");
  assertEq(flag, routerStorageHarness.getProtocolConfig().paused, "paused mismatch");
 }
}