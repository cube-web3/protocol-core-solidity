// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {IntegrationTest} from "@test/foundry/IntegrationTest.t.sol";
import {DemoAssertProtect} from "@test/demo/Demo.sol";
import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";
import {Structs} from "@src/common/Structs.sol";
import {ProtectionBase} from "@cube3/ProtectionBase.sol";

contract Integration_Assertion_Standlone_Concrete_Test is IntegrationTest {
    address public user;

    event ProtectionChecked(bool connected, uint256 payloadLength);

    function setUp() public override {
        super.setUp();
        user = _randomAddress();
    }

    function testAssertProtectWhenConnected_Connected() public {
        bytes memory payload = _createValidPayload();

        vm.expectEmit(true, true, false, true);
        emit ProtectionChecked(true, payload.length);

        vm.startPrank(user);
        demoAssertProtect.exposedAssertProtectWhenConnected(payload);
    }

    function testAssertProtectWhenConnected_Disconnected() public {
        bytes memory payload = _createValidPayload();

        demoAssertProtect.updateConnection(false);

        vm.expectEmit(true, true, false, true);
        emit ProtectionChecked(false, payload.length);
        vm.startPrank(user);
        demoAssertProtect.exposedAssertProtectWhenConnected(payload);
    }

    function testAssertProtectWhenConnected_InvalidPayloadSize() public {
        bytes memory invalidPayload = new bytes(31); // Less than MINIMUM_PAYLOAD_LENGTH_BYTES

        vm.startPrank(user);

        vm.expectRevert(ProtectionBase.Cube3Protection_InvalidPayloadSize.selector);
        demoAssertProtect.exposedAssertProtectWhenConnected(invalidPayload);
    }

    function testAssertProtectWhenConnected_ToggleConnection() public {
        bytes memory payload = _createValidPayload();
        vm.startPrank(user);
        // Start connected
        vm.expectEmit(true, true, false, true);
        emit ProtectionChecked(true, payload.length);
        demoAssertProtect.exposedAssertProtectWhenConnected(payload);

        // Disconnect
        payload = _createValidPayload();
        demoAssertProtect.updateConnection(false);
        vm.expectEmit(true, true, false, true);
        emit ProtectionChecked(false, payload.length);
        demoAssertProtect.exposedAssertProtectWhenConnected(payload);

        // Reconnect
        payload = _createValidPayload();
        demoAssertProtect.updateConnection(true);
        vm.expectEmit(true, true, false, true);
        emit ProtectionChecked(true, payload.length);
        demoAssertProtect.exposedAssertProtectWhenConnected(payload);
    }

    function testFuzz_AssertProtectWhenConnected(bytes calldata payload) public {
        vm.startPrank(user);
        if (payload.length >= 32) {
            vm.expectRevert(ProtectionBase.Cube3Protection_InvalidPayloadSize.selector);
            demoAssertProtect.exposedAssertProtectWhenConnected(payload[:31]);
        } else {
            vm.expectRevert(ProtectionBase.Cube3Protection_InvalidPayloadSize.selector);
            demoAssertProtect.exposedAssertProtectWhenConnected(payload);
        }
    }

    function _createValidPayload() internal returns (bytes memory) {
        bytes memory emptyBytes = new bytes(352);
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            DemoAssertProtect.exposedAssertProtectWhenConnected.selector,
            emptyBytes
        );

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demoAssertProtect),
                0,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        return
            PayloadCreationUtils.createCube3PayloadForSignatureModule(
                address(demoAssertProtect),
                user,
                demoSigningAuthorityPvtKey,
                1 days,
                true,
                signatureModule,
                topLevelCallComponents
            );
    }
}
