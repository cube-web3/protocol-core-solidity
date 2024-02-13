// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { ICube3SecurityModule } from "@src/interfaces/ICube3SecurityModule.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";

import { BaseTest } from "@test/foundry/BaseTest.t.sol";
// import {ProtocolEvents} from "@src/common/ProtocolEvents.sol";
import { MockRouter } from "@test/mocks/MockRouter.t.sol";
import { ModuleBaseHarness } from "@test/foundry/harnesses/ModuleBaseHarness.sol";


contract ModuleBase_Concrete_Unit_Test is BaseTest {
    ModuleBaseHarness moduleBaseHarness;
    MockRouter mockRouter;

    string constant VERSION_ONE = "version-0.0.1";
    uint256 constant PAYLOAD_SIZE = 69;
    bytes16 internal expectedId;

    function setUp() public override {
        expectedId = bytes16(bytes32(keccak256(abi.encode(VERSION_ONE))));
        mockRouter = new MockRouter();
    }

    /*//////////////////////////////////////////////////////////////
         moduleBase constructor
    //////////////////////////////////////////////////////////////*/

    // succeeds during deployment with valid router address, version, and payload size, and emits
    // the correct event
    function test_SucceedsWhen_RouterVersionAndPayloadAreValid() public {
        vm.expectEmit(true, true, true, true);
        emit ICube3SecurityModule.ModuleDeployed(address(mockRouter), expectedId, VERSION_ONE);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);

        assertEq(VERSION_ONE, moduleBaseHarness.moduleVersion(), "version mismatch");
        assertEq(expectedId, moduleBaseHarness.moduleId(), "id mismatch");
        assertFalse(moduleBaseHarness.isDeprecated(), "not deprecated");
    }

    // fails when the router is the zero address
    function test_RevertsWhen_RouterAddressIsZero() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_InvalidRouter.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(0), VERSION_ONE);
    }

    // fails with version that's too short
    function test_RevertsWhen_VersionStringTooShort() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version1");
    }

    // fails with a version that's too long
    function test_RevertsWhen_VersionStringTooLong() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "versionThatsTooLongBecauseItsOver32Bytes-0.0.1");
    }

    // fails with an invalid version schema
    function test_RevertsWhen_InvalidVersionSchemaUsed() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version0.0.1");

        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version-0.01");

        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version-1");
    }

    // fails with an invalid proxy
    function test_RevertsWhen_InvalidRouterAddressUsed() public {
        // expected return address
        vm.expectRevert();
        moduleBaseHarness = new ModuleBaseHarness(_randomAddress(), VERSION_ONE);
    }

    // fails when deploying the same version
    function test_RevertsWhen_DeployingDuplicateVersion() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);

        // mimic module installation
        mockRouter.setModule(expectedId, address(moduleBaseHarness));

        vm.expectRevert(ProtocolErrors.Cube3Module_ModuleVersionExists.selector);
        ModuleBaseHarness moduleBaseHarnessAlt = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);
        (moduleBaseHarnessAlt);
    }

    /*//////////////////////////////////////////////////////////////
         onlyCube3Router
    //////////////////////////////////////////////////////////////*/

    // fails when calling `deprecate` as an EOA
    function test_RevertsWhen_CallingDeprecate_AsEOA() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);
        vm.startPrank(_randomAddress());
        vm.expectRevert(ProtocolErrors.Cube3Module_OnlyRouterAsCaller.selector);
        moduleBaseHarness.deprecate();
    }

    // succeesd when calling `deprecate` as the router
    function test_SucceedsWhen_CallingDeprecate_AsRouter() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);

        vm.startPrank(address(mockRouter));
        vm.expectEmit(true, true, true, true);
        emit ICube3SecurityModule.ModuleDeprecated(moduleBaseHarness.moduleId(), VERSION_ONE);
        string memory version = moduleBaseHarness.deprecate();
        assertEq(keccak256(abi.encode(version)), keccak256(abi.encode(VERSION_ONE)), "version mismatch");
        assertTrue(moduleBaseHarness.isDeprecated(), "not deprecated");
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/

    // succeeds when checking interface support for ICube3SecurityModule and ERC165
    function test_SucceedsWhen_CheckingSupportedInterfaces() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);
        assertTrue(
            moduleBaseHarness.supportsInterface(type(ICube3SecurityModule).interfaceId),
            "ICube3SecurityModule not supported"
        );
        assertTrue(moduleBaseHarness.supportsInterface(type(IERC165).interfaceId), "ICube3SecurityModule not supported");
    }

    /*//////////////////////////////////////////////////////////////
            Version Schema
    //////////////////////////////////////////////////////////////*/
    function test_SucceedsWhen_VersionSchemaIsValid() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE);
        assertTrue(moduleBaseHarness.isValidVersionSchema("version-0.0.1"), "invalid version");
        assertTrue(moduleBaseHarness.isValidVersionSchema("version-0.6.9"), "invalid version");
        assertTrue(moduleBaseHarness.isValidVersionSchema("version-1.1.1"), "invalid version");
        assertTrue(moduleBaseHarness.isValidVersionSchema("version-v9.11.2"), "invalid version");

        assertFalse(moduleBaseHarness.isValidVersionSchema("v-0.1.1"), "invalid version");
        assertFalse(moduleBaseHarness.isValidVersionSchema("version-0.1"), "invalid version");
        assertFalse(moduleBaseHarness.isValidVersionSchema("version-1"), "invalid version");
        assertFalse(moduleBaseHarness.isValidVersionSchema("version-1.0"), "invalid version");
        assertFalse(moduleBaseHarness.isValidVersionSchema("version-9.11.2.3"), "invalid version");
        assertFalse(moduleBaseHarness.isValidVersionSchema("new-version-0.0.1"), "invalid version");
    }
}
