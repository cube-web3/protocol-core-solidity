// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

abstract contract TestEvents {
  event MockModuleCallSucceeded();
  event MockModuleCallSucceededWithArgs(bytes32 arg);

  // event SigningAuthorityRevoked(address indexed integration, address indexed revokedSigner);
  // event SigningAuthorityUpdated(address indexed integration, address indexed signer);
  // module base events
  // event ModuleDeployed(address indexed router, bytes32 indexed moduleId, string indexed version);
}