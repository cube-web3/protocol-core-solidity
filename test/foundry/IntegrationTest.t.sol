// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ICube3Router} from "@src/interfaces/ICube3Router.sol";
import {Demo, DemoAssertProtect} from "@test/demo/Demo.sol";
import {BaseTest} from "@test/foundry/BaseTest.t.sol";
import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";

abstract contract IntegrationTest is BaseTest {
    Demo internal demo;
    DemoAssertProtect internal demoAssertProtect;

    function setUp() public virtual override {
        super.setUp();
        _deployIntegrationDemos();
        _setDemoSigningAuthorityAsKeyManager(address(demo), demoSigningAuthorityPvtKey);
        _completeRegistrationAndEnableFnProtectionAsDemoDeployer();

        _setDemoSigningAuthorityAsKeyManager(address(demoAssertProtect), demoSigningAuthorityPvtKey);
        _completeRegistrationAndEnableFnProtectionForAssertionAsDemoDeployer();
    }

    function _deployIntegrationDemos() internal {
        vm.startPrank(cube3Accounts.demoDeployer);
        demo = new Demo(address(cubeRouterProxy));
        demoAssertProtect = new DemoAssertProtect(address(cubeRouterProxy));
        vm.stopPrank();
    }

    function _setDemoSigningAuthorityAsKeyManager(address integration, uint256 pvtKey) internal {
        vm.startPrank(cube3Accounts.keyManager);
        // set the signing authority
        registry.setClientSigningAuthority(integration, vm.addr(pvtKey));
        vm.stopPrank();
    }

    function _completeRegistrationAndEnableFnProtectionAsDemoDeployer() internal {
        vm.startPrank(cube3Accounts.demoDeployer);

        bytes4[] memory fnSelectors = new bytes4[](6);
        fnSelectors[0] = Demo.mint.selector;
        fnSelectors[1] = Demo.protected.selector;
        fnSelectors[2] = Demo.dynamic.selector;
        fnSelectors[3] = Demo.noArgs.selector;
        fnSelectors[4] = Demo.bytesProtected.selector;
        fnSelectors[5] = Demo.payableProtected.selector;

        bytes memory registrationSignature = PayloadCreationUtils.createRegistrarSignature(
            ICube3Router(address(cubeRouterProxy)).getIntegrationAdmin(address(demo)),
            address(demo),
            demoSigningAuthorityPvtKey
        );

        emit log_named_bytes("registrationSignature", registrationSignature);

        ICube3Router(address(cubeRouterProxy)).registerIntegrationWithCube3(
            address(demo),
            registrationSignature,
            fnSelectors
        );
        vm.stopPrank();
    }

    function _completeRegistrationAndEnableFnProtectionForAssertionAsDemoDeployer() internal {
        vm.startPrank(cube3Accounts.demoDeployer);

        bytes4[] memory fnSelectors = new bytes4[](1);
        fnSelectors[0] = DemoAssertProtect.exposedAssertProtectWhenConnected.selector;

        bytes memory registrationSignature = PayloadCreationUtils.createRegistrarSignature(
            ICube3Router(address(cubeRouterProxy)).getIntegrationAdmin(address(demoAssertProtect)),
            address(demoAssertProtect),
            demoSigningAuthorityPvtKey
        );

        emit log_named_bytes("registrationSignature", registrationSignature);

        ICube3Router(address(cubeRouterProxy)).registerIntegrationWithCube3(
            address(demoAssertProtect),
            registrationSignature,
            fnSelectors
        );
        vm.stopPrank();
    }
}
