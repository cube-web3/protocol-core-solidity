pragma solidity >=0.8.19 <0.8.24;

import "forge-std/Test.sol";

import {Demo} from "@test/demo/Demo.sol";
import {IntegrationTest} from "@test/foundry/IntegrationTest.t.sol";

import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";

import {Structs} from "@src/common/Structs.sol";

import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";

contract Integration_Modifier_Standlone_Concrete_Test is IntegrationTest {
    function setUp() public override {
        super.setUp();
    }

    // Succeeds when getting the implementation address by calling the proxy
    function test_SucceedsWhen_GettingProxyImplementationAddress() public {
        address implementation = wrappedRouterProxy.getImplementation();
        assertEq(implementation, address(routerImplAddr), "incorrect implementation");
    }

    // succeeds when routing to the module with no function args
    function test_SucceedsWhen_MintingWithValidPayload_WithNoValue() public {
        address user = _randomAddress();

        vm.startPrank(user);

        // test the modifier
        // generate the calldata for the integration function calls
        bytes memory emptyBytes = new bytes(352); //352
        bytes memory mintCalldataWithEmptyPayload = abi.encodeWithSelector(Demo.mint.selector, 99, emptyBytes);

        emit log_named_address("signatureModule", address(signatureModule));

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                0,
                mintCalldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        demo.mint(99, cube3SecurePayload);

        // test the assertion
        mintCalldataWithEmptyPayload = abi.encodeWithSelector(Demo.mintAssertion.selector, 69, emptyBytes);
        topLevelCallComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            user,
            address(demo),
            0,
            mintCalldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );
        cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );
        demo.mintAssertion(69, cube3SecurePayload);

        vm.stopPrank();
    }

    // succeeds when routing to the module with no dynamic type arguments
    function test_SucceedsWhen_CallingProtecteDemoFunction() public {
        address user = _randomAddress();

        vm.startPrank(user);

        uint256 newVal = 420;
        bool newState = true;
        bytes32 newBytes = keccak256(abi.encode(99, true, "hello"));

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length

        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.protected.selector,
            newVal,
            newState,
            newBytes,
            emptyBytes
        );

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                0,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        demo.protected(newVal, newState, newBytes, cube3SecurePayload);

        // test the assertion

        calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.protectedAssertion.selector,
            newVal,
            newState,
            newBytes,
            emptyBytes
        );

        topLevelCallComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            user,
            address(demo),
            0,
            calldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        demo.protectedAssertion(newVal, newState, newBytes, cube3SecurePayload);

        vm.stopPrank();
    }

    // succeeds when routing to the module with dynamic type arguments
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
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.dynamic.selector,
            vals,
            flag,
            str,
            emptyBytes
        );

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                0,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        emit log_named_bytes("cube3SecurePayload", cube3SecurePayload);

        demo.dynamic(vals, flag, str, cube3SecurePayload);

        // test the assertion
        calldataWithEmptyPayload = abi.encodeWithSelector(Demo.dynamicAssertion.selector, vals, flag, str, emptyBytes);

        topLevelCallComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            user,
            address(demo),
            0,
            calldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        emit log_named_bytes("cube3SecurePayload", cube3SecurePayload);

        demo.dynamicAssertion(vals, flag, str, cube3SecurePayload);
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
            Demo.bytesProtected.selector,
            firstBytes,
            newVal,
            secondBytes,
            uint256s,
            str,
            flag,
            emptyBytes
        );
        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                0,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        demo.bytesProtected(firstBytes, newVal, secondBytes, uint256s, str, flag, cube3SecurePayload);

        // test the assertion
        calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.bytesProtectedAssertion.selector,
            firstBytes,
            newVal,
            secondBytes,
            uint256s,
            str,
            flag,
            emptyBytes
        );
        topLevelCallComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            user,
            address(demo),
            0,
            calldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        demo.bytesProtectedAssertion(firstBytes, newVal, secondBytes, uint256s, str, flag, cube3SecurePayload);

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
                user,
                address(demo),
                0,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );
        demo.noArgs(cube3SecurePayload);

        // test the assertion
        calldataWithEmptyPayload = abi.encodeWithSelector(Demo.noArgsAssertion.selector, emptyBytes);
        topLevelCallComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            user,
            address(demo),
            0,
            calldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );
        demo.noArgsAssertion(cube3SecurePayload);

        vm.stopPrank();
    }

    function test_SucceedsWhen_PayableFunctionSucceeds() public {
        uint256 msgVal = 0.1 ether;
        address user = _randomAddress();

        vm.deal(user, msgVal * 2);
        vm.startPrank(user);

        uint256 newValue = 420;
        bool newState = true;
        bytes32 newBytes = keccak256(abi.encode(99, true, "hello"));

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.payableProtected.selector,
            newValue,
            newState,
            newBytes,
            emptyBytes
        );
        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                msgVal,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );
        demo.payableProtected{value: msgVal}(newValue, newState, newBytes, cube3SecurePayload);

        // test the assertion
        calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.payableProtectedAssertion.selector,
            newValue,
            newState,
            newBytes,
            emptyBytes
        );
        topLevelCallComponents = PayloadCreationUtils.packageTopLevelCallComponents(
            user,
            address(demo),
            msgVal,
            calldataWithEmptyPayload,
            EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
        );

        cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );
        demo.payableProtectedAssertion{value: msgVal}(newValue, newState, newBytes, cube3SecurePayload);
    }

    // succeeds when routing to the module with no function args
    function test_RevertsWhen_MintingWithValidPayload_WithDifferingPayload() public {
        address user = _randomAddress();

        vm.startPrank(user);

        uint256 qty = 99;

        // test the modifier
        // generate the calldata for the integration function calls
        bytes memory emptyBytes = new bytes(352); //352
        bytes memory mintCalldataWithEmptyPayload = abi.encodeWithSelector(Demo.mint.selector, qty, emptyBytes);

        emit log_named_address("signatureModule", address(signatureModule));

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                0,
                mintCalldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        vm.expectRevert(ProtocolErrors.Cube3SignatureUtils_InvalidSigner.selector);
        demo.mint(qty - 1, cube3SecurePayload);
    }

    function test_RevertsWhen_CallingProtecedFnWithDynamicTypedArgs_ArgsNotMatching() public {
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
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.dynamic.selector,
            vals,
            flag,
            str,
            emptyBytes
        );

        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                0,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );

        vals[1] = 420;
        vm.expectRevert(ProtocolErrors.Cube3SignatureUtils_InvalidSigner.selector);
        demo.dynamic(vals, flag, str, cube3SecurePayload);
    }

    function test_RevertsWhen_PayableFunctionWithNoValue() public {
        uint256 msgVal = 0.1 ether;
        address user = _randomAddress();

        vm.deal(user, msgVal * 2);
        vm.startPrank(user);

        uint256 newValue = 420;
        bool newState = true;
        bytes32 newBytes = keccak256(abi.encode(99, true, "hello"));

        // generate the payload
        bytes memory emptyBytes = new bytes(352); // payload length
        bytes memory calldataWithEmptyPayload = abi.encodeWithSelector(
            Demo.payableProtected.selector,
            newValue,
            newState,
            newBytes,
            emptyBytes
        );
        Structs.TopLevelCallComponents memory topLevelCallComponents = PayloadCreationUtils
            .packageTopLevelCallComponents(
                user,
                address(demo),
                msgVal,
                calldataWithEmptyPayload,
                EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH
            );

        bytes memory cube3SecurePayload = PayloadCreationUtils.createCube3PayloadForSignatureModule(
            address(demo),
            user,
            demoSigningAuthorityPvtKey,
            1 days,
            true,
            signatureModule,
            topLevelCallComponents
        );
        vm.expectRevert(ProtocolErrors.Cube3SignatureUtils_InvalidSigner.selector);
        demo.payableProtected{value: 0}(newValue, newState, newBytes, cube3SecurePayload);
    }
}
