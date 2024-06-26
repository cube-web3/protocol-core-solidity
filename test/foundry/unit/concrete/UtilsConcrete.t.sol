// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {BaseTest} from "@test/foundry/BaseTest.t.sol";
import {Structs} from "@src/common/Structs.sol";
import {MockRegistry} from "@test/mocks/MockRegistry.t.sol";
import {MockModule} from "@test/mocks/MockModule.t.sol";
import {MockCaller, MockTarget} from "@test/mocks/MockContract.t.sol";
import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";
import {UtilsHarness} from "@test/foundry/harnesses/UtilsHarness.sol";
import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";

contract Utils_Concrete_Unit_Test is BaseTest {
    UtilsHarness utilsHarness;

    function setUp() public override {
        utilsHarness = new UtilsHarness();
    }

    /*//////////////////////////////////////////////////////////////
        ADDRESS UTILS
    //////////////////////////////////////////////////////////////*/

    // fails when target contract is a contract under construction
    function test_RevertsWhen_TargetContractIsAContractUnderConstruction() public {
        MockTarget mockTarget = new MockTarget();

        // precompute the address of the MockCaller, as this will be the target contract that reverts
        address precomputed = computeCreateAddress(address(this), vm.getNonce(address(this)));

        // we expect the assertion to fail, even though target is a contract calling the `assertIsContract`,
        // due to the call taking place during the contract's deployment, therefore the code size is 0
        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Protocol_TargetNotAContract.selector, precomputed));
        MockCaller mockCaller = new MockCaller(address(mockTarget));
        (mockCaller);
    }

    // succeeds when the target address is a contract
    function test_SucceedsWhen_TargetIsAContract() public {
        MockTarget mockTarget = new MockTarget();
        assertTrue(utilsHarness.assertIsContract(address(mockTarget)));
    }

    // succeeds when the target address is an EOA
    function test_SucceedssWhen_TargetIsAnEoa() public view {
        utilsHarness.assertIsEOAorConstructorCall(_randomAddress());
    }

    // fails when the target address is a contract
    function test_RevertsWhen_TargetIsAContract() public {
        MockTarget mockTarget = new MockTarget();
        vm.expectRevert(
            abi.encodeWithSelector(ProtocolErrors.Cube3Protocol_TargetIsContract.selector, address(mockTarget))
        );
        utilsHarness.assertIsEOAorConstructorCall(address(mockTarget));
    }
}
