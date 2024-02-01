// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ModuleBase } from "../../../src/modules/ModuleBase.sol";

contract ModuleBaseHarness is ModuleBase {

constructor(address cubeRouterProxy, string memory version, uint256 payloadSize) ModuleBase(cubeRouterProxy,version, payloadSize) {}


/*//////////////////////////////////////////////////////////////
         moduleBase constructor
//////////////////////////////////////////////////////////////*/

// succeeds during deployment with valid router address, version, and payload size, and emits
// the correct event

// fails when the router is the zero address

// fails with version that's too short

// fails with a version that's too long

// fails with an invalid version schema

// fails with an invalid payload size

// fails with an invalid proxy

// fails when deploying the same version
}
