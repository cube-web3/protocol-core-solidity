pragma solidity >=0.8.19 < 0.8.24;

import "forge-std/Test.sol";

import { Demo } from "@test/demo/Demo.sol";
import { IntegrationTest } from "@test/foundry/IntegrationTest.t.sol";

import { PayloadCreationUtils } from "@test/libs/PayloadCreationUtils.sol";

import { Structs } from "@src/common/Structs.sol";

contract Integration_Standlone_Concrete_Test is IntegrationTest {
    function setUp() public override {
        super.setUp();
    }

    function test_SucceedsWhen_MintingWithValidPayload_WithNoValue() public {
        address user = _randomAddress();

        vm.startPrank(user);

        // generate the calldata for the integration function calls
        bytes memory emptyBytes = new bytes(352); //352
        bytes memory mintCalldataWithEmptyPayload = abi.encodeWithSelector(Demo.mint.selector, 99, emptyBytes);

        emit log_named_address("signatureModule", address(signatureModule));

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
            user, address(demo), 0, mintCalldataWithEmptyPayload, signatureModule.expectedPayloadSize()
        );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, true, signatureModule, topLevelCallComponents
        );

        emit log_named_bytes("cube3SecurePayload", cube3SecurePayload);
        demo.mint(99, cube3SecurePayload);

        vm.stopPrank();
    }


    function test_SucceedsWhen_CallingProtecteDemoFunction() public {
        address user = _randomAddress();

        vm.startPrank(user);

        uint256 newVal = 420;
        bool newState = true;
        bytes32 newBytes = keccak256(abi.encode(99, true, "hello"));

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length

        bytes memory calldataWithEmptyPayload =
            abi.encodeWithSelector(Demo.protected.selector, newVal, newState, newBytes, emptyBytes);

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
            user, address(demo), 0, calldataWithEmptyPayload, signatureModule.expectedPayloadSize()
        );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, true, signatureModule, topLevelCallComponents
        );

        demo.protected(newVal, newState, newBytes, cube3SecurePayload);
        vm.stopPrank();
    }

    function test_SucceedsWhen_CallingProtecedFnWithDynamicTypedArgs() public {
        address user = _randomAddress();

        vm.startPrank(user);

        uint256[] memory vals = new uint256[](3);
        vals[0] = 420;
        vals[1] = 69;
        vals[2] = 666;

        bool flag = false;
        string memory str = "Hello World";

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length
        bytes memory calldataWithEmptyPayload =
            abi.encodeWithSelector(Demo.dynamic.selector, vals, flag, str, emptyBytes);

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
            user, address(demo), 0, calldataWithEmptyPayload, signatureModule.expectedPayloadSize()
        );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, true, signatureModule, topLevelCallComponents
        );

        demo.dynamic(vals, flag, str, cube3SecurePayload);
        vm.stopPrank();
    }

    // Succeeds when calling a protected function that has dynamic types such as bytes as args
    function test_SucceedsWhen_CallingProtectedFnWithBytesArgs() public {
        address user = _randomAddress();

        vm.startPrank(user);

        bytes memory firstBytes = new bytes(169);
        uint256 newVal = 420;
        bytes memory secondBytes = abi.encode(69, true, "hello");
        uint256[] memory uint256s = new uint256[](3);
        uint256s[0] = 420;
        uint256s[1] = 69;
        uint256s[2] = 666;
        string memory str = "I got 99 problems but a string ain't one";
        bool flag = true;

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.bytesProtected.selector, firstBytes, newVal, secondBytes, uint256s, str, flag, emptyBytes
        );
        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
            user, address(demo), 0, calldataWithEmptyPayload, signatureModule.expectedPayloadSize()
        );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, true, signatureModule, topLevelCallComponents
        );

        demo.bytesProtected(firstBytes, newVal, secondBytes, uint256s, str, flag, cube3SecurePayload);
        vm.stopPrank();
    }

    // Succeeds when calling a protected function that has no arguments
    function test_SucceedsWhen_CallingProtectedFnWithNoArgs() public {
        address user = _randomAddress();

        vm.startPrank(user);

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(Demo.noArgs.selector, emptyBytes);
        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
            user, address(demo), 0, calldataWithEmptyPayload, signatureModule.expectedPayloadSize()
        );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, true, signatureModule, topLevelCallComponents
        );
        demo.noArgs(cube3SecurePayload);
        vm.stopPrank();
    }

    function testPayable() public { }
}
