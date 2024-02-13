// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import {ModuleBaseEvents} from "@src/modules/ModuleBaseEvents.sol";
import { BaseTest } from "@test/foundry/BaseTest.t.sol";
import { Structs } from "@src/common/Structs.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { ProtocolManagement } from "@src/abstracts/ProtocolManagement.sol";
import { RouterStorageHarness } from "@test/foundry/harnesses/RouterStorageHarness.sol";
import { MockModule, MockModuleCustomDeprecate } from "@test/mocks/MockModule.t.sol";
import { MockRegistry } from "@test/mocks/MockRegistry.t.sol";



contract ProtocolManagement_Concrete_Unit_Test is BaseTest {
    MockRegistry mockRegistry;
    MockModule mockModule;
    MockModuleCustomDeprecate mockModuleCustomDeprecate;

    string constant MODULE_VERSION = "mockModule-0.0.1";

    function setUp() public override {
        // BaseTest.setUp();
        _createCube3Accounts();
        _deployTestingHarnessContracts();

        protocolManagementHarness.grantRole(CUBE3_PROTOCOL_ADMIN_ROLE, cube3Accounts.protocolAdmin);

        mockModule = new MockModule(address(protocolManagementHarness), MODULE_VERSION);
        mockModuleCustomDeprecate = new MockModuleCustomDeprecate(address(protocolManagementHarness), MODULE_VERSION);
        mockRegistry = new MockRegistry();
    }

    /*//////////////////////////////////////////////////////////////
         updateProtocolConfig
    //////////////////////////////////////////////////////////////*/

    // succeeds when the registry is set
    function test_SucceedsWhen_ProtocolConfigIsSet(uint256 pausedFlag) public {
        bool paused = pausedFlag % 2 == 0;

        vm.startPrank(cube3Accounts.protocolAdmin);

        // set the config
        vm.expectEmit(true, true, true, true);
        emit ProtocolConfigUpdated(address(mockRegistry), paused);
        protocolManagementHarness.updateProtocolConfig(address(mockRegistry), paused);
        vm.stopPrank();

        // check the config values
        assertEq(address(mockRegistry), protocolManagementHarness.getProtocolConfig().registry, "registry mismatch");
        assertEq(paused, protocolManagementHarness.getProtocolConfig().paused, "paused mismatch");
    }

    // succeeds when setting the registry to the zero address and emits special event
    function test_SucceedsWhen_SettingRegistryToZeroAddress() public {
        vm.startPrank(cube3Accounts.protocolAdmin);

        // set the config
        vm.expectEmit(true, true, true, true);
        emit ProtocolConfigUpdated(address(0), false);
        emit ProtocolRegistryRemoved();
        protocolManagementHarness.updateProtocolConfig(address(0), false);
        vm.stopPrank();

        // check the config values
        assertEq(address(0), protocolManagementHarness.getProtocolConfig().registry, "registry mismatch");
    }

    // fails when a non-priveleged role tries to set the config
    function test_RevertsWhen_NonPrivilegedRoleSetsConfig() public {
        // set the config
        vm.expectRevert();
        protocolManagementHarness.updateProtocolConfig(address(mockRegistry), false);
        vm.stopPrank();
    }

    // fails when an incorrect registry address is passed
    function test_RevertsWhen_SettingIncorrectRegistry() public {
        vm.startPrank(cube3Accounts.protocolAdmin);

        // set the config
        vm.expectRevert(ProtocolErrors.Cube3Router_NotValidRegistryInterface.selector);
        protocolManagementHarness.updateProtocolConfig(_randomAddress(), true);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
         callModuleFunctionAsAdmin
    //////////////////////////////////////////////////////////////*/

    // succeeds when called by an admin, the module exists, and the module call succeeds,
    // and returns the correct return data
    function test_SucceedsWhen_CallingModuleFunction_AsProtocolAdmin() public {
        bytes16 moduleId = _installModuleAsAdmin();

        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectEmit(true, true, true, true);
        emit MockModuleCallSucceeded();
        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.privilegedFunction.selector);
        bytes memory harnessCalldata =
            abi.encodeWithSelector(ProtocolManagement.callModuleFunctionAsAdmin.selector, moduleId, moduleCalldata);
        (bool success, bytes memory returnRevert) = address(protocolManagementHarness).call(harnessCalldata);
        require(success, "harness call failed");
        // decode the return data that's encoded as bytes returned by {callModuleFunctionAsAdmin}
        bytes32 returnedArg = abi.decode(abi.decode(returnRevert, (bytes)), (bytes32));
        assertEq(returnedArg, mockModule.SUCCESSFUL_RETURN(), "invalid return");
    }

    // fails when module function is called by a non admin
    function test_RevertsWhen_CallingModuleFunction_AsNonProtocolAdmin() public {
        address randomAccount = _randomAddress();

        bytes16 moduleId = _installModuleAsAdmin();

        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.privilegedFunction.selector);
        bytes memory harnessCalldata =
            abi.encodeWithSelector(ProtocolManagement.callModuleFunctionAsAdmin.selector, moduleId, moduleCalldata);

        vm.startPrank(randomAccount);
        vm.expectRevert();
        (bool success,) = address(protocolManagementHarness).call(harnessCalldata);
        require(success, "harness call failed");
    }

    // fails when called by an admin, with a valid module, but the module fn reverts
    function test_RevertsWhen_WithValidModuleAndModuleReverts_AsAdmin() public {
        bytes16 moduleId = _installModuleAsAdmin();

        vm.startPrank(cube3Accounts.protocolAdmin);
        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.privilegedFunctionThatReverts.selector);
        bytes memory harnessCalldata =
            abi.encodeWithSelector(ProtocolManagement.callModuleFunctionAsAdmin.selector, moduleId, moduleCalldata);

        vm.expectRevert(bytes("FAILED"));
        (bool success,) = address(protocolManagementHarness).call(harnessCalldata);
        require(success, "harness call failed");
    }

    /*//////////////////////////////////////////////////////////////
            installModule
    //////////////////////////////////////////////////////////////*/

    // succeeds when installing a valid module
    function test_SucceedsWhen_InstallingValidModule() public {
        _installModuleAsAdmin();
    }

    // fails when moduleAddress is the zero address
    function test_RevertsWhen_ModuleAddressIsZeroAddress() public {
        bytes16 moduleId = bytes16(bytes32(keccak256("unusedId")));
        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectRevert(ProtocolErrors.Cube3Router_InvalidAddressForModule.selector);
        protocolManagementHarness.installModule(address(0), moduleId);
    }

    // fails when the moduleId is invalid
    function test_RevertsWhen_ModuleIdIsInvalid() public {
        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectRevert(ProtocolErrors.Cube3Router_InvalidIdForModule.selector);
        protocolManagementHarness.installModule(address(mockModule), bytes16(0));
    }

    // fails when an invalid address for the module is passed
    function test_RevertsWhen_InvalidModuleAddressIsPassed() public {
        bytes16 moduleId = bytes16(bytes32(keccak256("unusedId")));
        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectRevert(ProtocolErrors.Cube3Router_ModuleInterfaceNotSupported.selector);
        protocolManagementHarness.installModule(_randomAddress(), moduleId);
    }

    // fails when installing a module that's already installed
    function test_RevertsWhen_InstallingAnExistingModule() public {
        _installModuleAsAdmin();
        vm.startPrank(cube3Accounts.protocolAdmin);
        bytes16 moduleId = mockModule.moduleId();
        vm.expectRevert(ProtocolErrors.Cube3Router_ModuleAlreadyInstalled.selector);
        protocolManagementHarness.installModule(address(mockModule), moduleId);
        vm.stopPrank();
    }

    // fails when deploying a module whose ID doesn't match the version
    function test_RevertsWhen_ModuleIdNotMatchingVersion() public {
        MockModule altMockModule = new MockModule(address(protocolManagementHarness), "noduleVersion-0.0.2");

        bytes16 altModuleId = altMockModule.moduleId();

        // overwrite the module with a different version
        protocolManagementHarness.setModuleInstalled(altModuleId, address(0), "noduleVersion-0.0.2");
        vm.startPrank(cube3Accounts.protocolAdmin);

        vm.expectRevert(ProtocolErrors.Cube3Router_ModuleVersionNotMatchingID.selector);
        protocolManagementHarness.installModule(address(mockModule), altModuleId);
    }

    // fails reinstalling a module that's been deprecated
    function test_RevertsWhen_ReInstallingDeprecatedModule() public {
        bytes16 moduleId = _installModuleAsAdmin();

        // deprecate the current module
        vm.startPrank(cube3Accounts.protocolAdmin);
        protocolManagementHarness.deprecateModule(moduleId);

        // deploy the same module version
        MockModule duplicate = new MockModule(address(protocolManagementHarness), MODULE_VERSION);
        bytes16 duplicateId = duplicate.moduleId();

        // attempt to reinstall it
        vm.expectRevert(ProtocolErrors.Cube3Router_CannotInstallDeprecatedModule.selector);
        protocolManagementHarness.installModule(address(mockModule), duplicateId);
    }

    /*//////////////////////////////////////////////////////////////
            deprecateModule
    //////////////////////////////////////////////////////////////*/

    // succeeds depracting an existing module, which removes the module
    // and emits the correct events
    function test_SucceedsWhen_DeprecatingExistingModule() public {
        bytes16 moduleId = _installModuleAsAdmin();
        vm.startPrank(cube3Accounts.protocolAdmin);

        // the deprecation event is emitted
        vm.expectEmit(true, true, true, true);
        emit RouterModuleDeprecated(moduleId, address(mockModule), MODULE_VERSION);

        // the removal event is emiited
        vm.expectEmit(true, true, true, true);
        emit RouterModuleRemoved(moduleId);

        protocolManagementHarness.deprecateModule(moduleId);
        assertTrue(protocolManagementHarness.getIsModuleVersionDeprecated(moduleId), "module not deprecated");
        assertEq(address(0), protocolManagementHarness.getModuleAddressById(moduleId), "module not removed");
    }

    // fails deprecating a module which reverts in {deprecate}
    function test_RevertsWhen_ModuleDeprecateFnReverts() public {
        bytes16 moduleId = _installModuleAsAdmin();
        mockModule.updatePreventDeprecation(true);

        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectRevert(ProtocolErrors.Cube3Router_ModuleDeprecationFailed.selector);
        protocolManagementHarness.deprecateModule(moduleId);
    }

    /*//////////////////////////////////////////////////////////////
         deprecate override
    //////////////////////////////////////////////////////////////*/

    // Succeeds when deprecating a module when overriding the deprecate fn to
    // add additional functionality
    function test_SucceedsWhen_CallingOverriddenDeprecate_AsRouter() public {

        // in this instance, the harness is the router from the module's perspective
        vm.startPrank(address(protocolManagementHarness));
        vm.expectEmit(true, true, true, true);
        emit ModuleBaseEvents.ModuleDeprecated(mockModuleCustomDeprecate.moduleId(), MODULE_VERSION);
        vm.expectEmit(true, true, true, true);
        emit CustomDeprecation();
        string memory version = mockModuleCustomDeprecate.deprecate();
        assertEq(keccak256(abi.encode(version)), keccak256(abi.encode("custom deprecation")), "version mismatch");
        assertTrue(mockModuleCustomDeprecate.isDeprecated(), "not deprecated");
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
         HELPERS
    //////////////////////////////////////////////////////////////*/
    function _installModuleAsAdmin() internal returns (bytes16 moduleId) {
        vm.startPrank(cube3Accounts.protocolAdmin);
        moduleId = mockModule.moduleId();
        protocolManagementHarness.installModule(address(mockModule), moduleId);
        vm.stopPrank();
    }
}
