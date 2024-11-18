// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Cube3RouterImpl} from "@src/Cube3RouterImpl.sol";
import {Cube3Registry} from "@src/Cube3Registry.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";
import {Structs} from "@src/common/Structs.sol";
import {DemoIntegrationERC721} from "@test/demo/DemoIntegrationERC721.sol";
import {DeployUtils} from "./utils/DeployUtils.sol";
import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";

contract DeploySepolia is Script, DeployUtils {
    uint256 internal DEPLOYER_SEPOLIA_PVT_KEY;
    address deployer;

    uint256 internal KEY_MANAGER_SEPOLIA_PVT_KEY;
    address keyManager;

    uint256 INTEGRATION_ADMIN_SEPOLIA_PVT_KEY;
    address integrationAdmin;

    uint256 internal SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY;
    address backupSigner;

    uint256 constant SIGNATURE_MODULE_LENGTH = 320;

    string signatureModuleVersion = "signature-0.0.4";

    address PROTOCOL_MULTISIG = 0x8a83f062c272d720DA6590daD156A24242ddD0De;

    function run() public {
        if (block.chainid != 11_155_111) revert("not sepolia");
        _loadAccountsFromEnv();

        uint256 deployerPvtKey = DEPLOYER_SEPOLIA_PVT_KEY;

        // The deployer account is by default assigned the DEFAULT_ADMIN_ROLE, which gives is sudo privileges.
        // We use the deployer to assign all the relevant accounts their roles. 
        
        // Once the deployment is complete, we must manually revoke the deployer's DEFAULT_ADMIN_ROLE via the the multisig.
        // which serves as a confirmation step that the multisig is correctly configured
        vm.startBroadcast(deployerPvtKey);

        // For the duration of the deployment, the deployer is the default admin
        _deployProtocol(
            DEPLOYER_SEPOLIA_PVT_KEY,
            keyManager,
            integrationAdmin,
            backupSigner,
            signatureModuleVersion
        );

        // install the module
        // wrappedRouterProxy.installModule(
        //     address(signatureModule),
        //     bytes16(keccak256(abi.encode(signatureModuleVersion)))
        // );

        // set all the role permissions
        _addAccessControlAndRevokeDeployerPermsForRegistry(PROTOCOL_MULTISIG, keyManager, vm.addr(deployerPvtKey));
        _addAccessControlAndRevokeDeployerPermsForRouter(PROTOCOL_MULTISIG, integrationAdmin, vm.addr(deployerPvtKey));

        vm.stopBroadcast();

    }

    function _loadAccountsFromEnv() internal {
        DEPLOYER_SEPOLIA_PVT_KEY = vm.envUint("DEPLOYER_SEPOLIA_PVT_KEY");
        deployer = vm.addr(DEPLOYER_SEPOLIA_PVT_KEY);

        KEY_MANAGER_SEPOLIA_PVT_KEY = vm.envUint("KEY_MANAGER_SEPOLIA_PVT_KEY");
        keyManager = vm.addr(KEY_MANAGER_SEPOLIA_PVT_KEY);

        INTEGRATION_ADMIN_SEPOLIA_PVT_KEY = vm.envUint("INTEGRATION_ADMIN_SEPOLIA_PVT_KEY");
        integrationAdmin = vm.addr(INTEGRATION_ADMIN_SEPOLIA_PVT_KEY);

        SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY = vm.envUint("SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY");
        backupSigner = vm.addr(SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY);
    }
}
