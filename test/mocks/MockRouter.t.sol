// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

contract MockRouter {

 mapping(bytes16 => address) modules; // id => module

 function getModuleAddressById(bytes16 id) external view returns(address) {
  return modules[id];
 }

 function setModule(bytes16 id, address module) external {
  modules[id] = module;
 }
}