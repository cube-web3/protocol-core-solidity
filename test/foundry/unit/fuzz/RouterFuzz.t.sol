// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { BaseTest } from "../../BaseTest.t.sol";

import { RouterHarness } from "../../harnesses/RouterHarness.sol";
import { MockModule } from "../../../mocks/MockModule.t.sol";

import { ProtocolErrors } from "../../../../src/libs/ProtocolErrors.sol";
import { ICube3Router } from "../../../../src/interfaces/ICube3Router.sol";

import { Structs } from "../../../../src/common/Structs.sol";

contract Router_Fuzz_Unit_Test is BaseTest {
    RouterHarness routerHarness;
    MockModule mockModule;

    function setUp() public {
        routerHarness = new RouterHarness();
        mockModule = new MockModule(address(routerHarness), "version-0.0.1", 69);
    }

    /*//////////////////////////////////////////////////////////////
            _shouldBypassRouting
    //////////////////////////////////////////////////////////////*/

    // succeeds (returns true) when the integration's registration status is revoked
    function testFuzz_SucceedsWhen_BypassingRouting_WhenIntegrationRegistrationStatusIsRevoked() public {
        address integration = _randomAddress();

        routerHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REVOKED);

        vm.startPrank(integration);
        assertTrue(routerHarness.shouldBypassRouting(0x12345678));
    }

    // succeeds (returns true) bypassing the router when function protection is disabled
    function testFuzz_SucceedsWhen_BypassingRouting_WhenFunctionProtectionIsDisabled(uint256 selectorSeed) public {
        vm.assume(selectorSeed > 0);

        address integration = _randomAddress();
        bytes4 selector = bytes4(keccak256(abi.encode(selectorSeed)));
        vm.startPrank(integration);
        assertTrue(routerHarness.shouldBypassRouting(selector));
    }

    /*//////////////////////////////////////////////////////////////
            _executeModuleFunctionCall
    //////////////////////////////////////////////////////////////*/

    // fails when the module is an EOA, the call to the module will succeed, but the
    // response will be invalid
    function testFuzz_RevertsWhen_ModuleIsEOA(uint256 byteLength) public {
        byteLength = bound(byteLength, 1, 2048);
        address module = _randomAddress();
        bytes memory moduleCalldata = new bytes(byteLength);

        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Router_ModuleReturnDataInvalidLength.selector, 0));
        routerHarness.executeModuleFunctionCall(module, moduleCalldata);
    }

    // fails if moduleCalldata is empty and the module's fallback is called, thus
    // there is no revert data
    function testFuzz_RevertsWhen_ModuleCalldataIsEmpty() public {
        bytes memory moduleCalldata = new bytes(0);
        vm.expectRevert();
        routerHarness.executeModuleFunctionCall(address(mockModule), moduleCalldata);
    }

    // fails if moduleCalldata doesn't match function
    function testFuzz_RevertsWhen_ModuleCalldataHasUnknownSelector(uint256 byteLength) public {
        byteLength = bound(byteLength, 4, 2048);
        bytes memory moduleCalldata = _getRandomBytes(byteLength);

        vm.expectRevert();
        routerHarness.executeModuleFunctionCall(address(mockModule), moduleCalldata);
    }

    // fails if module call reverts
    function testFuzz_RevertsWhen_ModuleCallReverts(uint256 dataSeed) public {
        bytes32 arg = keccak256(abi.encode(dataSeed));

        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.executeMockModuleFunction.selector, arg);
        mockModule.updateForceRevert(true);
        vm.expectRevert(bytes("Forced Revert"));
        routerHarness.executeModuleFunctionCall(address(mockModule), moduleCalldata);
    }

    // fails if return data is not 32 bytes
    function testFuzz_RevertsWhen_ReturnDataLengthNot32Bytes(uint256 dataSeed) public {
        bytes32 arg = keccak256(abi.encode(dataSeed));
        bytes memory moduleCalldata =
            abi.encodeWithSelector(MockModule.executeMockModuleFunctionInvalidReturnDataLength.selector, arg);
        // we know the mock module returns 64 bytes: bytes32 + uint256
        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Router_ModuleReturnDataInvalidLength.selector, 64));
        routerHarness.executeModuleFunctionCall(address(mockModule), moduleCalldata);
    }

    // fails if return data is not bytes32 value of MODULE_CALL_SUCCEEDED
    function testFuzz_RevertsWhen_ReturnDataNotMatchingExpected(uint256 dataSeed) public {
        bytes32 arg = keccak256(abi.encode(dataSeed));
        bytes memory moduleCalldata =
            abi.encodeWithSelector(MockModule.executeMockModuleFunctionInvalidReturnDataType.selector, arg);
        vm.expectRevert(ProtocolErrors.Cube3Router_ModuleReturnedInvalidData.selector);
        routerHarness.executeModuleFunctionCall(address(mockModule), moduleCalldata);
    }
    // Succeeds if the module returns MODULE_CALL_SUCCEEDED

    function testFuzz_SucceedsWhen_ReturnDataMatchesExpected(uint256 dataSeed) public {
        bytes32 arg = keccak256(abi.encode(dataSeed));
        bytes memory moduleCalldata = abi.encodeWithSelector(MockModule.executeMockModuleFunction.selector, arg);
        vm.expectEmit(true, true, true, true);
        emit MockModuleCallSucceededWithArgs(arg);
        bytes32 resp = routerHarness.executeModuleFunctionCall(address(mockModule), moduleCalldata);
        assertEq(resp, PROCEED_WITH_CALL, "invalid return");
    }
}
