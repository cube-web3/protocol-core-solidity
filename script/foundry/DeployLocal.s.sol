// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import "forge-std/Script.sol";

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Cube3RouterImpl } from "@src/Cube3RouterImpl.sol";
import { Cube3Registry } from "@src/Cube3Registry.sol";
import { Cube3SignatureModule } from "@src/modules/Cube3SignatureModule.sol";

import { DemoIntegrationERC721 } from "../../test/demo/DemoIntegrationERC721.sol";
import { DeployUtils } from "./utils/DeployUtils.sol";

import { SignatureUtils } from "./utils/SignatureUtils.sol";

import { PayloadUtils } from "./utils/PayloadUtils.sol";

import { Structs } from "@src/common/Structs.sol";

contract DeployLocal is Script, DeployUtils, SignatureUtils, PayloadUtils {
    DemoIntegrationERC721 demo;

    uint256 deployerPvtKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // anvil [0]
    address deployer;

    uint256 keyManagerPvtKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; // anvil [1]
    address keyManager;

    uint256 cubeAdminPvtKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a; // anvil [2]
    address cube3admin;

    uint256 cube3integrationAdminPvtKey = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a; // anvil
        // [4]
    address cube3integrationAdmin;

    uint256 backupSignerPvtKey = 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97; // anvil[8]
    address backupSigner;

    uint256 demoDeployerPvtKey = 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e;
    address demoDeployer;

    uint256 demoSigningAuthorityPvtKey = uint256(69);
    address demoSigningAuthority;

    string version = "signature-0.0.1";

    constructor() { }

    function setUp() external {
        backupSigner = vm.addr(backupSignerPvtKey);
        deployer = vm.addr(deployerPvtKey);
        cube3integrationAdmin = vm.addr(cube3integrationAdminPvtKey);
        keyManager = vm.addr(keyManagerPvtKey);
        cube3admin = vm.addr(cubeAdminPvtKey);
        demoDeployer = vm.addr(demoDeployerPvtKey);
        demoSigningAuthority = vm.addr(demoSigningAuthorityPvtKey);
    }

    function run() external {
        // install module
        vm.startBroadcast(cube3admin);
        wrappedRouterProxy.installModule(address(signatureModule), bytes16(keccak256(abi.encode(version))));
        vm.stopBroadcast();

        _deployDemoAsDemoDeployer();

        _setDemoSigningAuthorityAsKeyManager();

        _completeRegistrationAndEnableFnProtectionAsDemoDeployer();

        _demoMintAsUser();
    }

    function _deployDemoAsDemoDeployer() internal {
        vm.startBroadcast(demoDeployerPvtKey);
        // deploy the contract
        demo = new DemoIntegrationERC721(address(cubeRouterProxy));
        vm.stopBroadcast();
    }

    function _setDemoSigningAuthorityAsKeyManager() internal {
        vm.startBroadcast(keyManagerPvtKey);
        // set the signing authority
        registry.setClientSigningAuthority(address(demo), demoSigningAuthority);
        vm.stopBroadcast();
    }

    function _completeRegistrationAndEnableFnProtectionAsDemoDeployer() internal {
        vm.startBroadcast(demoDeployerPvtKey);
        // deploy the contract
        Structs.FunctionProtectionStatusUpdate[] memory fnProtectionData =
            new Structs.FunctionProtectionStatusUpdate[](1);
        fnProtectionData[0] = Structs.FunctionProtectionStatusUpdate({
            fnSelector: DemoIntegrationERC721.safeMint.selector,
            protectionEnabled: true
        });
        bytes4[] memory fnSelectors = new bytes4[](1);
        fnSelectors[0] = DemoIntegrationERC721.safeMint.selector;

        bytes memory registrationSignature =
            _generateRegistrarSignature(address(cubeRouterProxy), address(demo), demoSigningAuthorityPvtKey);
        wrappedRouterProxy.registerIntegrationWithCube3(address(demo), registrationSignature, fnSelectors);
        vm.stopBroadcast();
    }

    function _demoMintAsUser() internal {
        uint256 callerPvtKey = uint256(666);
        address caller = vm.addr(callerPvtKey);

        vm.startBroadcast(caller);
        bytes memory emptyBytes = new bytes(PAYLOAD_LENGTH);

        bytes memory calldataWithEmptyPayload =
            abi.encodeWithSelector(DemoIntegrationERC721.safeMint.selector, 3, emptyBytes);
        Structs.TopLevelCallComponents memory topLevelCallComponents =
            _createIntegrationCallInfo(caller, address(demo), 0, calldataWithEmptyPayload);

        bytes memory cube3SecurePayload = _createPayload(
            address(demo), caller, demoSigningAuthorityPvtKey, 1 days, signatureModule, topLevelCallComponents
        );

        demo.safeMint(3, cube3SecurePayload);
        vm.stopBroadcast();
    }
}
