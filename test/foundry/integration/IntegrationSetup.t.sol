// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { BaseTest } from "../BaseTest.t.sol";

import { Demo } from "../../demo/Demo.sol";

import { ICube3Router } from "../../../src/interfaces/ICube3Router.sol";

abstract contract IntegrationSetup is BaseTest {
    Demo demo;

    function setUp() public virtual {
        // deploy and configure cube protocol
        _createCube3Accounts();

        _deployProtocol();

        _installSignatureModuleInRouter();

        emit log_named_address("router proxy", address(cubeRouterProxy));
        vm.startPrank(cube3Accounts.demoDeployer);
        demo = new Demo(address(cubeRouterProxy));
        vm.stopPrank();

        // _setDemoSigningAuthorityAsKeyManager(address(demo), demoSigningAuthorityPvtKey);

        // // complete the registration
        // _completeRegistrationAndEnableFnProtectionAsDemoDeployer(demoSigningAuthorityPvtKey);
    }

    function _setDemoSigningAuthorityAsKeyManager(address loan, uint256 pvtKey) internal {
        vm.startPrank(keyManager);
        // set the signing authority
        registry.setClientSigningAuthority(loan, vm.addr(pvtKey));
        vm.stopPrank();
    }

    function _completeRegistrationAndEnableFnProtectionAsDemoDeployer(uint256 demoAuthPvtKey) internal {
        vm.startPrank(demoDeployer);

        // deploy the contract
        // ICube3Data.FunctionProtectionStatusUpdate[] memory fnProtectionData =
        //     new ICube3Data.FunctionProtectionStatusUpdate[](1);
        // fnProtectionData[0] = ICube3Data.FunctionProtectionStatusUpdate({fnSelector: selector, protectionEnabled:
        // true});

        bytes4[] memory fnSelectors = new bytes4[](6);
        fnSelectors[0] = Demo.mint.selector;
        fnSelectors[1] = Demo.protected.selector;
        fnSelectors[2] = Demo.dynamic.selector;
        fnSelectors[3] = Demo.noArgs.selector;
        fnSelectors[4] = Demo.bytesProtected.selector;
        fnSelectors[5] = Demo.payableProtected.selector;

        bytes memory registrationSignature =
            _generateRegistrarSignature(address(cubeRouterProxy), address(demo), demoAuthPvtKey);

        emit log_named_bytes("registrationSignature", registrationSignature);

        ICube3Router(address(cubeRouterProxy)).registerIntegrationWithCube3(
            address(demo), registrationSignature, fnSelectors
        );
        vm.stopPrank();
    }
}
