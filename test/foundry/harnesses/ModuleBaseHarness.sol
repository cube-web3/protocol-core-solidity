// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ModuleBase } from "@src/modules/ModuleBase.sol";

/// @notice Testing Harness for the abstract ModuleBase contract.
contract ModuleBaseHarness is ModuleBase {
    constructor(
        address cubeRouterProxy,
        string memory version
    )
        ModuleBase(cubeRouterProxy, version)
    { }

    function isValidVersionSchema(string memory version) external pure returns (bool) {
        return _isValidVersionSchema(version);
    }
}
