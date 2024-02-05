// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { BaseTest } from "../../BaseTest.t.sol";

import { RegistryHarness } from "../../harnesses/RegistryHarness.sol";

contract Registry_Fuzz_Unit_Test is BaseTest {
    RegistryHarness registryHarness;

    function setUp() public {
        _createCube3Accounts();
        registryHarness = new RegistryHarness();
    }

    /*//////////////////////////////////////////////////////////////
            batchSetSigningAuthority
    //////////////////////////////////////////////////////////////*/
}
