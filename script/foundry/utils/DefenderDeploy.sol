// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {DefenderOptions} from "openzeppelin-foundry-upgrades/Options.sol";

import {Cube3RouterImpl} from "@src/Cube3RouterImpl.sol";
import {Cube3Registry} from "@src/Cube3Registry.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";

struct NetworkDeploymentDetails {
    string deployerRelayerId; // ID of the relayer responsible for deployments
    string upgradeApprovalProcessId; // ID of the upgrade approval process (multisig)
    bytes32 deploymentSalt; // Salt used for CREATE2 deployments
    address registryBackupSigner; // Address of the backup signer
    string signatureModuleVersion; // Version of the signature module
    address relayerAdmin;
}

abstract contract DefenderDeploy is Script {
    address internal registry;
    address internal routerProxy;

    function setUp() public virtual {}

    function run(NetworkDeploymentDetails memory networkOpts) public {
        ApprovalProcessResponse memory upgradeApprovalProcess = Defender.getUpgradeApprovalProcess();
        if (upgradeApprovalProcess.via == address(0)) {
            revert(
                string.concat(
                    "Upgrade approval process with id ",
                    upgradeApprovalProcess.approvalProcessId,
                    " has no assigned address"
                )
            );
        }

        _deployRegistry(networkOpts.deployerRelayerId, networkOpts.deploymentSalt, networkOpts.relayerAdmin);
        _deployRouter(networkOpts.deployerRelayerId, networkOpts.deploymentSalt, networkOpts.upgradeApprovalProcessId);
        _deploySignatureModule(
            networkOpts.deployerRelayerId,
            networkOpts.deploymentSalt,
            networkOpts.signatureModuleVersion,
            networkOpts.registryBackupSigner
        );
    }

    function _deployRegistry(string memory relayerId, bytes32 salt, address relayerAdmin) internal {
        DefenderOptions memory opts;
        opts.useDefenderDeploy = true;
        opts.relayerId = relayerId;
        opts.salt = salt;

        ApprovalProcessResponse memory deploymentApprovalProcess = Defender.getDeployApprovalProcess();
        if (deploymentApprovalProcess.via == address(0)) {
            revert(
                string.concat(
                    "Upgrade approval process with id ",
                    deploymentApprovalProcess.approvalProcessId,
                    " has no assigned address"
                )
            );
        }
        console.log("Deploy approval process address", deploymentApprovalProcess.via);
        console.log("Deploy approval process ID", deploymentApprovalProcess.approvalProcessId);
        console.log("Deploy approval type", deploymentApprovalProcess.viaType);

        registry = Defender.deployContract("Cube3Registry.sol", abi.encode(relayerAdmin), opts);
        console.log("Deployed Registry contract to address", registry);
    }

    function _deployRouter(string memory relayerId, bytes32 salt, string memory upgradeApprovalProcessId) internal {
        // TODO: pass in registry address
        Options memory opts;
        opts.defender.useDefenderDeploy = true;
        opts.defender.relayerId = relayerId;
        opts.defender.salt = salt;
        opts.defender.upgradeApprovalProcessId = upgradeApprovalProcessId;

        routerProxy = Upgrades.deployUUPSProxy(
            "Cube3RouterImpl.sol",
            abi.encodeCall(Cube3RouterImpl.initialize, registry),
            opts
        );

        console.log("Deployed Router Proxy contract to address", routerProxy);
    }

    function _deploySignatureModule(
        string memory relayerId,
        bytes32 salt,
        string memory signatureModuleVersion,
        address backupSigner
    ) internal {
        if (routerProxy == address(0)) {
            revert("RouterProxy not deployed");
        }
        DefenderOptions memory opts;
        opts.useDefenderDeploy = true;
        opts.relayerId = relayerId;
        opts.salt = salt;

        registry = Defender.deployContract(
            "Cube3SignatureModule.sol",
            abi.encode(routerProxy, signatureModuleVersion, backupSigner),
            opts
        );
        console.log("Deployed Registry contract to address", registry);
    }
}
