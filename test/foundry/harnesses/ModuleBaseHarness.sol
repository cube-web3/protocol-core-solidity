// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ModuleBase } from "../../../src/modules/ModuleBase.sol";

/// @notice Testing Harness for the abstract ModuleBase contract.
contract ModuleBaseHarness is ModuleBase {
    constructor(
        address cubeRouterProxy,
        string memory version,
        uint256 payloadSize
    )
        ModuleBase(cubeRouterProxy, version, payloadSize)
    { }

    function isValidVersionSchema(string memory version) external pure returns (bool) {
        return _isValidVersionSchema(version);
    }
}
