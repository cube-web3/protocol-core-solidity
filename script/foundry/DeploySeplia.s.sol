// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Cube3Router} from "../../src/Cube3Router.sol";
import {Cube3Registry} from "../../src/Cube3Registry.sol";
import {Cube3SignatureModule} from "../../src/modules/Cube3SignatureModule.sol";

import {DemoIntegrationERC721} from "../../test/foundry/demo/DemoIntegrationERC721.sol";
import {DeployUtils} from "./utils/DeployUtils.sol";

import {RegistrarUtils} from "./utils/RegistrarUtils.sol";

import {PayloadUtils} from "./utils/PayloadUtils.sol";

import {Structs} from "../../src/common/Structs.sol";

contract DeploySepolia is Script, DeployUtils, RegistrarUtils, PayloadUtils {

 uint256 internal V2_DEPLOYER_SEPOLIA_PVT_KEY;
 address deployerV2;

 uint256 internal V2_KEY_MANAGER_SEPOLIA_PVT_KEY;
 address keyManagerV2;

 uint256 internal V2_PROTOCOL_ADMIN_SEPOLIA_PVT_KEY;
 address protocolAdminV2;

 uint256 V2_INTEGRATION_ADMIN_SEPOLIA_PVT_KEY;
 address integrationAdminV2;

 uint256 internal V2_SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY;
 address backupSignerV2;

 uint256 constant SIGNATURE_MODULE_LENGTH = 320;

 string signatureModuleVersion = "signature-0.0.1";

 function run() public {
  if (block.chainid != 11155111) { revert("not sepolia"); }
  _loadAccountsFromEnv();

 // calls startBroadcast internally
  _deployProtocol(
   V2_DEPLOYER_SEPOLIA_PVT_KEY, 
   protocolAdminV2, 
   keyManagerV2, 
   integrationAdminV2, 
   backupSignerV2, 
   SIGNATURE_MODULE_LENGTH, 
   signatureModuleVersion
  );

  vm.startBroadcast(V2_PROTOCOL_ADMIN_SEPOLIA_PVT_KEY);
    wrappedRouterProxy.installModule(address(signatureModule), bytes16(keccak256(abi.encode(signatureModuleVersion))));
  vm.stopBroadcast();

 }

 function _loadAccountsFromEnv() internal {
  V2_DEPLOYER_SEPOLIA_PVT_KEY = vm.envUint("V2_DEPLOYER_SEPOLIA_PVT_KEY");
  deployerV2 = vm.addr(V2_DEPLOYER_SEPOLIA_PVT_KEY);

  V2_KEY_MANAGER_SEPOLIA_PVT_KEY = vm.envUint("V2_KEY_MANAGER_SEPOLIA_PVT_KEY");
  keyManagerV2 = vm.addr(V2_KEY_MANAGER_SEPOLIA_PVT_KEY);

  V2_PROTOCOL_ADMIN_SEPOLIA_PVT_KEY = vm.envUint("V2_PROTOCOL_ADMIN_SEPOLIA_PVT_KEY");
  protocolAdminV2 = vm.addr(V2_PROTOCOL_ADMIN_SEPOLIA_PVT_KEY);

  V2_INTEGRATION_ADMIN_SEPOLIA_PVT_KEY = vm.envUint("V2_INTEGRATION_ADMIN_SEPOLIA_PVT_KEY");
  integrationAdminV2 = vm.addr(V2_INTEGRATION_ADMIN_SEPOLIA_PVT_KEY);

  V2_SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY = vm.envUint("V2_SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY");
  backupSignerV2 = vm.addr(V2_SIGNATURE_MODULE_BACKUP_SIGNER_SEPOLIA_PVT_KEY);
 }

}