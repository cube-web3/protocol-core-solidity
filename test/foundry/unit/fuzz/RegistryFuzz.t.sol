// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { BaseTest } from "../../BaseTest.t.sol";

import {ProtocolErrors} from "../../../../src/libs/ProtocolErrors.sol";
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

    function testFuzz_RevertsWhen_IntegrationAndSigningAuthorityArraysDontMatch_AsKeyManager(uint256 lenIntegrations, uint256 lenAuthorities) public {
        lenAuthorities = bound(lenAuthorities, 0, 100);
        lenIntegrations = bound(lenIntegrations, 0, 100);
        vm.assume(lenIntegrations != lenAuthorities);

        address[] memory integrations = new address[](lenIntegrations);
        address[] memory authorities = new address[](lenAuthorities);

        for (uint256 i; i < lenIntegrations; i++) {
            integrations[i] = _randomAddress();
        }

        for (uint256 i; i < lenAuthorities; i++) {
            authorities[i] = _randomAddress();
        }

        // set the appropriate role
        registryHarness.grantRole(CUBE3_KEY_MANAGER_ROLE, cube3Accounts.keyManager);

        vm.startPrank(cube3Accounts.keyManager);
        vm.expectRevert(ProtocolErrors.Cube3Protocol_ArrayLengthMismatch.selector);
        registryHarness.batchSetSigningAuthority(integrations, authorities);
    }
}
