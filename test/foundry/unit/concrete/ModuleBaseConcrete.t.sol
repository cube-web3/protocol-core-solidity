// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { BaseTest } from "../../BaseTest.t.sol";
// import {ProtocolEvents} from "@src/common/ProtocolEvents.sol";
import { MockRouter } from "../../../mocks/MockRouter.t.sol";
import { ModuleBaseHarness } from "../../harnesses/ModuleBaseHarness.sol";
import { ICube3Module } from "@src/interfaces/ICube3Module.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { ModuleBaseEvents } from "@src/modules/ModuleBaseEvents.sol";

contract ModuleBase_Concrete_Unit_Test is BaseTest, ModuleBaseEvents {
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
        emit ModuleDeployed(address(mockRouter), expectedId, VERSION_ONE);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);

        assertEq(VERSION_ONE, moduleBaseHarness.moduleVersion(), "version mismatch");
        assertEq(expectedId, moduleBaseHarness.moduleId(), "id mismatch");
        assertEq(PAYLOAD_SIZE, moduleBaseHarness.expectedPayloadSize(), "payload size mismatch");
        assertFalse(moduleBaseHarness.isDeprecated(), "not deprecated");
    }

    // fails when the router is the zero address
    function test_RevertsWhen_RouterAddressIsZero() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_InvalidRouter.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(0), VERSION_ONE, PAYLOAD_SIZE);
    }

    // fails with version that's too short
    function test_RevertsWhen_VersionStringTooShort() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version1", PAYLOAD_SIZE);
    }

    // TODO: check revert message is correct
    // fails with a version that's too long
    function test_RevertsWhen_VersionStringTooLong() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness =
            new ModuleBaseHarness(address(mockRouter), "versionThatsTooLongBecauseItsOver32Bytes-0.0.1", PAYLOAD_SIZE);
    }

    // fails with an invalid version schema
    function test_RevertsWhen_InvalidVersionSchemaUsed() public {
        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version0.0.1", PAYLOAD_SIZE);

        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version-0.01", PAYLOAD_SIZE);

        vm.expectRevert(ProtocolErrors.Cube3Module_DoesNotConformToVersionSchema.selector);
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), "version-1", PAYLOAD_SIZE);
    }

    // fails with an invalid payload size
    function test_RevertsWhen_PayloadSizeIsZero() public {
        vm.expectRevert(bytes("TODO: invalid payload size"));
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, 0);
    }

    // fails with an invalid proxy
    function test_RevertsWhen_InvalidRouterAddressUsed() public {
        // expected return address
        vm.expectRevert();
        moduleBaseHarness = new ModuleBaseHarness(_randomAddress(), VERSION_ONE, 69);
    }

    // fails when deploying the same version
    function test_RevertsWhen_DeployingDuplicateVersion() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);

        // mimic module installation
        mockRouter.setModule(expectedId, address(moduleBaseHarness));

        vm.expectRevert(ProtocolErrors.Cube3Module_ModuleVersionExists.selector);
        ModuleBaseHarness moduleBaseHarnessAlt = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);
    }

    /*//////////////////////////////////////////////////////////////
         onlyCube3Router
    //////////////////////////////////////////////////////////////*/

    // fails when calling `deprecate` as an EOA
    function test_RevertsWhen_CallingDeprecateAsEOA() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);
        vm.startPrank(_randomAddress());
        vm.expectRevert(ProtocolErrors.Cube3Module_OnlyRouterAsCaller.selector);
        moduleBaseHarness.deprecate();
    }

    // succeesd when calling `deprecate` as the router
    function test_SucceedsWhen_CallingDeprecateAsRouter() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);

        vm.startPrank(address(mockRouter));
        vm.expectEmit(true, true, true, true);
        emit ModuleDeprecated(moduleBaseHarness.moduleId(), VERSION_ONE);
        string memory version = moduleBaseHarness.deprecate();
        assertEq(keccak256(abi.encode(version)), keccak256(abi.encode(VERSION_ONE)), "version mismatch");
        assertTrue(moduleBaseHarness.isDeprecated(), "not deprecated");
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/

    // succeeds when checking interface support for ICube3Module and ERC165
    function test_SucceedsWhen_CheckingSupportedInterfaces() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);
        assertTrue(moduleBaseHarness.supportsInterface(type(ICube3Module).interfaceId), "ICube3Module not supported");
        assertTrue(moduleBaseHarness.supportsInterface(type(IERC165).interfaceId), "ICube3Module not supported");
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/
    function test_SucceedsWhen_VersionSchemaIsValid() public {
        moduleBaseHarness = new ModuleBaseHarness(address(mockRouter), VERSION_ONE, PAYLOAD_SIZE);
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
