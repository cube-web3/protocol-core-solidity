// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SecurityModuleBase} from "@src/modules/SecurityModuleBase.sol";

/// @notice Testing Harness for the abstract SecurityModuleBase contract.
contract ModuleBaseHarness is SecurityModuleBase {
    constructor(address cubeRouterProxy, string memory version) SecurityModuleBase(cubeRouterProxy, version) {}

    function isValidVersionSchema(string memory version) external pure returns (bool) {
        return _isValidVersionSchema(version);
    }
}
