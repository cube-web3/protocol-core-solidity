pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { DeployUtils } from "../../script/foundry/utils/DeployUtils.sol";

import { PayloadUtils } from "../../script/foundry/utils/PayloadUtils.sol";

import { Cube3Router } from "../../src/Cube3Router.sol";

import { Cube3Registry } from "../../src/Cube3Registry.sol";
import { Cube3SignatureModule } from "../../src/modules/Cube3SignatureModule.sol";

import { ICube3Router } from "../../src/interfaces/ICube3Router.sol";

import { Demo } from "../demo/Demo.sol";

import {ProtocolEvents} from "../../src/common/ProtocolEvents.sol";
import {RouterStorageHarness} from "./harnesses/RouterStorageHarness.sol";

contract BaseTest is DeployUtils, PayloadUtils, ProtocolEvents {
    using ECDSA for bytes32;

    Demo public demo;

    RouterStorageHarness routerStorageHarness;

    // cube
    uint256 internal deployerPvtKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // anvil [0]
    address internal deployer;

    uint256 internal keyManagerPvtKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; // anvil [1]
    address internal keyManager;

    uint256 internal cubeAdminPvtKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a; // anvil [2]
    address internal cube3admin;

    uint256 internal cube3integrationAdminPvtKey = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a; // anvil
        // [4]
    address internal cube3integrationAdmin;

    uint256 internal backupSignerPvtKey = 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97; // anvil[8]
    address internal backupSigner;

    uint256 internal demoSigningAuthorityPvtKey = uint256(69);
    address internal demoSigningAuthority;

    uint256 internal demoDeployerPrivateKey = uint256(420);
    address internal demoDeployer;

    address internal user = vm.addr(42_069);

    string internal version = "signature-0.0.1";

    // TODO: change to setUp
    function initProtocol() internal {
        // deploy and configure cube protocol
        _createAccounts();
        _deployTestingContracts();
        _deployProtocol();
        _installSignatureModuleInRouter();

        vm.startPrank(demoDeployer);
        demo = new Demo(address(cubeRouterProxy));
        vm.stopPrank();

        _setDemoSigningAuthorityAsKeyManager(address(demo), demoSigningAuthorityPvtKey);

        // complete the registration
        _completeRegistrationAndEnableFnProtectionAsDemoDeployer(demoSigningAuthorityPvtKey);
    }

    // ============= TESTS

    // ============= CUBE

    function _createAccounts() internal {
        backupSigner = vm.addr(backupSignerPvtKey);
        deployer = vm.addr(deployerPvtKey);
        cube3integrationAdmin = vm.addr(cube3integrationAdminPvtKey);
        keyManager = vm.addr(keyManagerPvtKey);
        cube3admin = vm.addr(cubeAdminPvtKey);
        demoSigningAuthority = vm.addr(demoSigningAuthorityPvtKey);
        demoDeployer = vm.addr(demoDeployerPrivateKey);

        // labels
        vm.label(demoSigningAuthority, "Laon Signing Authority");
    }

    function _deployTestingContracts() internal {
        routerStorageHarness = new RouterStorageHarness();
    }

    function _deployProtocol() internal {
        emit log_string("Deploying protocol");

        vm.startPrank(deployer, deployer);

        // ============ registry
        registry = new Cube3Registry();
        vm.label(address(registry), "Cube3Registry");

        _addAccessControlAndRevokeDeployerPermsForRegistry(cube3admin, keyManager, deployer);

        // ============ router
        // deploy the implementation
        routerImplAddr = address(new Cube3Router());

        vm.label(routerImplAddr, "Cube3RouterImpl");

        // deploy the proxy
        cubeRouterProxy = new ERC1967Proxy(routerImplAddr, abi.encodeCall(Cube3Router.initialize, (address(registry))));
        vm.label(address(cubeRouterProxy), "CubeRouterProxy");

        // create a wrapper interface (for convenience)
        wrappedRouterProxy = Cube3Router(payable(address(cubeRouterProxy)));
        _addAccessControlAndRevokeDeployerPermsForRouter(cube3admin, cube3integrationAdmin, deployer);

        // =========== signature module
        signatureModule = new Cube3SignatureModule(address(cubeRouterProxy), version, backupSigner, 320);
        vm.label(address(signatureModule), "Cube3SignatureModule");

        vm.stopPrank();
    }

    function _installSignatureModuleInRouter() internal {
        emit log_string("installing signature module");
        // install module
        vm.startPrank(cube3admin);
        wrappedRouterProxy.installModule(address(signatureModule), bytes16(keccak256(abi.encode(version))));
        vm.stopPrank();
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

    // ============== UTILS

    function _generateRegistrarSignature(
        address router,
        address integration,
        uint256 signingAuthPvtKey
    )
        internal
        returns (bytes memory)
    {
        emit log_string("generating reg sig");
        address integrationSecurityAdmin = ICube3Router(router).getIntegrationAdmin(integration);
        return
            _createSignature(abi.encodePacked(integration, integrationSecurityAdmin, block.chainid), signingAuthPvtKey);
    }

    function _createSignature(
        bytes memory encodedSignatureData,
        uint256 pvtKeyToSignWith
    )
        private
        returns (bytes memory signature)
    {
        bytes32 signatureHash = keccak256(encodedSignatureData);
        bytes32 ethSignedHash = signatureHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

        signature = abi.encodePacked(r, s, v);

        (, ECDSA.RecoverError error) = ethSignedHash.tryRecover(signature);
        if (error != ECDSA.RecoverError.NoError) {
            revert("No Matchies");
        }
    }
}
