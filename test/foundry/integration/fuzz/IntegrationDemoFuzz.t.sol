pragma solidity >=0.8.19 < 0.8.24;

import "forge-std/Test.sol";

import { Demo } from "@test/demo/Demo.sol";
import { IntegrationTest } from "@test/foundry/IntegrationTest.t.sol";

import { PayloadCreationUtils } from "@test/libs/PayloadCreationUtils.sol";

import { Structs } from "@src/common/Structs.sol";

contract Integration_Standlone_Fuzz_Test is IntegrationTest {
    function setUp() public override {
        super.setUp();
    }


    function testFuzz_SucceedsWhen_CallingProtectedPayableFunction_WithEther(uint256 value) public {
        value = bound(value, 1, type(uint128).max);
        bool flag = value % 2 == 0;
        bytes32 randomBytes32 = keccak256(abi.encode(value));

        address user = _randomAddress();
        vm.deal(user, value);

        bytes memory emptyBytes = new bytes(352); //352
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(Demo.payableProtected.selector, value, flag, randomBytes32, emptyBytes);

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
            user, address(demo), value, calldataWithEmptyPayload, EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, false, signatureModule, topLevelCallComponents
        );

        vm.startPrank(user);
        uint256 contractBalance = address(demo).balance;
        vm.expectEmit(true,true,true,true);
        emit BalanceUpdated(address(demo), contractBalance + value);
        demo.payableProtected{value: value}(value, flag, randomBytes32, cube3SecurePayload);
        vm.stopPrank();
    }


}