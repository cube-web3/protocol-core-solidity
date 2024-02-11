// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import "forge-std/Test.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { DeployUtils } from "../../script/foundry/utils/DeployUtils.sol";

import { PayloadUtils } from "../../script/foundry/utils/PayloadUtils.sol";

import { Cube3Router } from "../../src/Cube3Router.sol";
import { Cube3Registry } from "../../src/Cube3Registry.sol";
import { Cube3SignatureModule } from "../../src/modules/Cube3SignatureModule.sol";
import { ICube3Router } from "../../src/interfaces/ICube3Router.sol";
import { ProtocolEvents } from "../../src/common/ProtocolEvents.sol";
import { RouterStorageHarness } from "./harnesses/RouterStorageHarness.sol";
import { ProtocolManagementHarness } from "./harnesses/ProtocolManagementHarness.sol";

import { ProtocolAdminRoles } from "../../src/common/ProtocolAdminRoles.sol";
import { ProtocolConstants } from "../../src/common/ProtocolConstants.sol";
import { TestUtils } from "../utils/TestUtils.t.sol";
import { TestEvents } from "../utils/TestEvents.t.sol";

import { Demo } from "../demo/Demo.sol";

struct Accounts {
    address deployer;
    address keyManager;
    address protocolAdmin;
    address integrationManager;
    address backupSigner;
    address demoSigningAuthority;
    address demoDeployer;
}

contract BaseTest is DeployUtils, PayloadUtils, ProtocolEvents, TestUtils, TestEvents, ProtocolConstants {
    using ECDSA for bytes32;

    // Test-specific contracts
    RouterStorageHarness routerStorageHarness;
    ProtocolManagementHarness protocolManagementHarness;

    Accounts cube3Accounts;

    // cube
    uint256 internal deployerPvtKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80; // anvil [0]
    uint256 internal keyManagerPvtKey = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d; // anvil [1]
    uint256 internal cubeAdminPvtKey = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a; // anvil [2]
    uint256 internal cube3integrationAdminPvtKey = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a; // anvil
        // [4]

    uint256 internal backupSignerPvtKey = 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97; // anvil[8]
    uint256 internal demoSigningAuthorityPvtKey = uint256(69);
    uint256 internal demoDeployerPrivateKey = uint256(420);

    string internal version = "signature-0.0.1";

    function setUp() public virtual {
        // deploy and configure cube protocol
        _createCube3Accounts();
        _deployTestingHarnessContracts();
        _deployProtocol();
        _installSignatureModuleInRouter();
    }

    // ============= TESTS

    // ============= CUBE

    function _createCube3Accounts() internal {
        cube3Accounts = Accounts({
            backupSigner: vm.addr(backupSignerPvtKey),
            deployer: vm.addr(deployerPvtKey),
            integrationManager: vm.addr(cube3integrationAdminPvtKey),
            keyManager: vm.addr(keyManagerPvtKey),
            protocolAdmin: vm.addr(cubeAdminPvtKey),
            demoSigningAuthority: vm.addr(demoSigningAuthorityPvtKey),
            demoDeployer: vm.addr(demoDeployerPrivateKey)
        });

        // labels

    }

    function _deployTestingHarnessContracts() internal {
        routerStorageHarness = new RouterStorageHarness();
        protocolManagementHarness = new ProtocolManagementHarness();
    }

    function _deployProtocol() internal {
        emit log_string("Deploying protocol");

        vm.startPrank(cube3Accounts.deployer, cube3Accounts.deployer);

        // ============ registry
        registry = new Cube3Registry();
        vm.label(address(registry), "Cube3Registry");

        _addAccessControlAndRevokeDeployerPermsForRegistry(cube3Accounts.protocolAdmin, cube3Accounts.keyManager, cube3Accounts.deployer);

        // ============ router
        // deploy the implementation
        routerImplAddr = address(new Cube3Router());

        vm.label(routerImplAddr, "Cube3RouterImpl");

        // deploy the proxy
        cubeRouterProxy = new ERC1967Proxy(routerImplAddr, abi.encodeCall(Cube3Router.initialize, (address(registry))));
        vm.label(address(cubeRouterProxy), "CubeRouterProxy");

        // create a wrapper interface (for convenience)
        wrappedRouterProxy = Cube3Router(payable(address(cubeRouterProxy)));
        _addAccessControlAndRevokeDeployerPermsForRouter(cube3Accounts.protocolAdmin, cube3Accounts.integrationManager, cube3Accounts.deployer);

        // =========== signature module
        signatureModule = new Cube3SignatureModule(address(cubeRouterProxy), version, cube3Accounts.backupSigner, 320);
        vm.label(address(signatureModule), "Cube3SignatureModule");

        vm.stopPrank();
    }

    function _installSignatureModuleInRouter() internal {
        emit log_string("installing signature module");
        // install module
        vm.startPrank(cube3Accounts.protocolAdmin);
        wrappedRouterProxy.installModule(address(signatureModule), bytes16(keccak256(abi.encode(version))));
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

    // TODO: move to ustils
    function _createSignature(
        bytes memory encodedSignatureData,
        uint256 pvtKeyToSignWith
    )
        internal
        returns (bytes memory signature)
    {
        bytes32 signatureHash = keccak256(encodedSignatureData);
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(signatureHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvtKeyToSignWith, ethSignedHash);

        signature = abi.encodePacked(r, s, v);

        (, ECDSA.RecoverError error,) = ethSignedHash.tryRecover(signature);
        if (error != ECDSA.RecoverError.NoError) {
            revert("No Matchies");
        }
    }
}
