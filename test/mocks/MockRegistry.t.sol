// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MockRegistry {

 function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
  // account for InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
  if (interfaceId == 0xffffffff) return false;
  else return true;
 }
}