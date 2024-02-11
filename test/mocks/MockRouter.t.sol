// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import {ProtocolConstants} from "../../src/common/ProtocolConstants.sol";

contract MockRouter is ProtocolConstants {

 address public registry;

 mapping(bytes16 => address) modules; // id => module

 function setRegistryAddress(address _registry) external {
  registry = _registry;
 }

 function getRegistryAddress() external view returns(address) {
  return registry;
 }
 function getModuleAddressById(bytes16 id) external view returns(address) {
  return modules[id];
 }

 function setModule(bytes16 id, address module) external {
  modules[id] = module;
 }
}