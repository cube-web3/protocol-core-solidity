// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "@src/common/Structs.sol";
import { MockRegistry } from "../../../mocks/MockRegistry.t.sol";
import { MockModule } from "../../../mocks/MockModule.t.sol";

import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { ProtocolManagement } from "@src/abstracts/ProtocolManagement.sol";

contract ProtocolManagement_Fuzz_Unit_Test is BaseTest {
    MockRegistry mockRegistry;
    MockModule mockModule;

    string constant MODULE_VERSION = "mockModule-0.0.1";

    function setUp() public override {
        // BaseTest.setUp();
        _createCube3Accounts();
        _deployTestingHarnessContracts();

        protocolManagementHarness.grantRole(CUBE3_PROTOCOL_ADMIN_ROLE, cube3Accounts.protocolAdmin);

        mockModule = new MockModule(address(protocolManagementHarness), MODULE_VERSION, 69);
        mockRegistry = new MockRegistry();
    }
    /*//////////////////////////////////////////////////////////////
         callModuleFunctionAsAdmin
    //////////////////////////////////////////////////////////////*/

    // succeeds when called by an admin, the module exists, and the module call succeeds,
    // and returns the correct return data
    function testFuzz_SucceedsWhen_CalledByAnAdminWithModuleInstalledAndValidReturnUsingArgs(uint256 argSeed) public {
        bytes32 arg = keccak256(abi.encodePacked(argSeed));
        bytes16 moduleId = _installModuleAsAdmin();

        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectEmit(true, true, true, true);
        emit MockModuleCallSucceededWithArgs(arg);
        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.privilegedFunctionWithArgs.selector, arg);
        bytes memory harnessCalldata =
            abi.encodeWithSelector(ProtocolManagement.callModuleFunctionAsAdmin.selector, moduleId, moduleCalldata);
        (bool success, bytes memory returnRevert) = address(protocolManagementHarness).call(harnessCalldata);
        require(success, "harness call failed");
        // decode the return data that's encoded as bytes returned by {callModuleFunctionAsAdmin}
        bytes32 returnedArg = abi.decode(abi.decode(returnRevert, (bytes)), (bytes32));
        assertEq(returnedArg, arg, "invalid return");
    }

    // fails when called by an admin with an invalid module address
    function testFuzz_RevertsWhen_CalledByAnAdminWithAnInvalidModule(uint256 moduleSeed) public {
        moduleSeed = bound(moduleSeed, 1, type(uint256).max);

        _installModuleAsAdmin();

        bytes16 moduleId = bytes16(bytes32(keccak256(abi.encode(moduleSeed))));
        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.privilegedFunction.selector);
        bytes memory harnessCalldata =
            abi.encodeWithSelector(ProtocolManagement.callModuleFunctionAsAdmin.selector, moduleId, moduleCalldata);

        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Router_ModuleNotInstalled.selector, moduleId));
        (bool success, bytes memory returnRevert) = address(protocolManagementHarness).call(harnessCalldata);
    }

    // fails when the module doesn't exist
    function testFuzz_RevertsWhen_CalledModuleNotInstalled_AsAdmin(uint256 moduleSeed) public {
        moduleSeed = bound(moduleSeed, 1, type(uint256).max);
        bytes16 moduleId = bytes16(bytes32(keccak256(abi.encode(moduleSeed))));
        vm.startPrank(cube3Accounts.protocolAdmin);
        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.privilegedFunctionThatReverts.selector);
        bytes memory harnessCalldata =
            abi.encodeWithSelector(ProtocolManagement.callModuleFunctionAsAdmin.selector, moduleId, moduleCalldata);

        vm.expectRevert(ProtocolErrors.Cube3Router_ModuleNotInstalled.selector);
        (bool success, bytes memory returnRevert) = address(protocolManagementHarness).call(harnessCalldata);
    }

    /*//////////////////////////////////////////////////////////////
            deprecateModule
    //////////////////////////////////////////////////////////////*/

    // fails deprecating a non-existent module
    function testFuzz_RevertsWhen_DeprecatingNonExistentModule(uint256 moduleSeed) public {
        bytes16 nonExistentModuleId = bytes16(bytes32(moduleSeed));

        vm.startPrank(cube3Accounts.protocolAdmin);
        vm.expectRevert(
            abi.encodeWithSelector(ProtocolErrors.Cube3Router_ModuleNotInstalled.selector, nonExistentModuleId)
        );
        protocolManagementHarness.deprecateModule(nonExistentModuleId);
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
