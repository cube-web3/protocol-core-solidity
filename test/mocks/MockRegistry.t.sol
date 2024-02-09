// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

contract MockRegistry {

 mapping(address => address) public signatureAuthorities; // integration => signatureAuthority

 function setSignatureAuthorityForIntegration(address integration, address authority) external {
  signatureAuthorities[integration] = authority;
 }

 function getSignatureAuthorityForIntegration(address integration) external view returns (address) {
  return signatureAuthorities[integration];
 }

 function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
  // account for InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
  if (interfaceId == 0xffffffff) return false;
  else return true;
 }
}