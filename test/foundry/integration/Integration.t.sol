pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { Demo } from "../../demo/Demo.sol";
import { BaseTest } from "../BaseTest.t.sol";

import { Structs } from "../../../src/common/Structs.sol";

contract IntegrationTest is BaseTest {
    function setUp() public {
        // deploy and configure cube protocol
        _createAccounts();
        _deployProtocol();
        _installSignatureModuleInRouter();

        vm.startPrank(demoDeployer);
        demo = new Demo(address(cubeRouterProxy));
        vm.stopPrank();

        _setDemoSigningAuthorityAsKeyManager(address(demo), demoSigningAuthorityPvtKey);

        // // complete the registration
        _completeRegistrationAndEnableFnProtectionAsDemoDeployer(demoSigningAuthorityPvtKey);
    }

    function testMint() public {
        vm.startPrank(user);

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length

        bytes memory mintCalldataWithEmptyPayload = abi.encodeWithSelector(Demo.mint.selector, 99, emptyBytes);

        Structs.IntegrationCallMetadata memory integrationCallInfo =
            _createIntegrationCallInfo(user, address(demo), 0, mintCalldataWithEmptyPayload, signatureModule);

        bytes memory cube3SecurePayload = _createPayload(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, signatureModule, integrationCallInfo
        );

        emit log_named_bytes("cube3SecurePayload", cube3SecurePayload);
        uint256 prevBalance = demo.mint(99, cube3SecurePayload);

        vm.stopPrank();
    }

    function testProtected() public {
        vm.startPrank(user);

        uint256 newVal = 420;
        bool newState = true;
        bytes32 newBytes = keccak256(abi.encode(99, true, "hello"));

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length

        bytes memory calldataWithEmptyPayload =
            abi.encodeWithSelector(Demo.protected.selector, newVal, newState, newBytes, emptyBytes);

        Structs.IntegrationCallMetadata memory integrationCallInfo =
            _createIntegrationCallInfo(user, address(demo), 0, calldataWithEmptyPayload, signatureModule);

        bytes memory cube3SecurePayload = _createPayload(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, signatureModule, integrationCallInfo
        );

        demo.protected(newVal, newState, newBytes, cube3SecurePayload);
        vm.stopPrank();
    }

    function testDynamic() public {
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
        Structs.IntegrationCallMetadata memory integrationCallInfo =
            _createIntegrationCallInfo(user, address(demo), 0, calldataWithEmptyPayload, signatureModule);

        bytes memory cube3SecurePayload = _createPayload(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, signatureModule, integrationCallInfo
        );
        demo.dynamic(vals, flag, str, cube3SecurePayload);
        vm.stopPrank();
    }

    function testBytes() public {
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
        Structs.IntegrationCallMetadata memory integrationCallInfo =
            _createIntegrationCallInfo(user, address(demo), 0, calldataWithEmptyPayload, signatureModule);

        bytes memory cube3SecurePayload = _createPayload(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, signatureModule, integrationCallInfo
        );
        demo.bytesProtected(firstBytes, newVal, secondBytes, uint256s, str, flag, cube3SecurePayload);
        vm.stopPrank();
    }

    function testNoArgs() public {
        vm.startPrank(user);

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(Demo.noArgs.selector, emptyBytes);
        Structs.IntegrationCallMetadata memory integrationCallInfo =
            _createIntegrationCallInfo(user, address(demo), 0, calldataWithEmptyPayload, signatureModule);

        bytes memory cube3SecurePayload = _createPayload(
            address(demo), user, demoSigningAuthorityPvtKey, 1 days, signatureModule, integrationCallInfo
        );
        demo.noArgs(cube3SecurePayload);
        vm.stopPrank();
    }

    function testPayable() public { }
}
