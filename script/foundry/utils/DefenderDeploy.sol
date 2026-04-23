// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {DefenderOptions, TxOverrides} from "openzeppelin-foundry-upgrades/Options.sol";

import {Cube3RouterImpl} from "@src/Cube3RouterImpl.sol";
import {Cube3Registry} from "@src/Cube3Registry.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";

struct DeployGasConfig {
    uint256 gasPrice;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
}
struct NetworkDeploymentDetails {
    address protocolAdmin;
    string deployerRelayerId; // ID of the relayer responsible for deployments
    string upgradeApprovalProcessId; // ID of the upgrade approval process (multisig)
    bytes32 deploymentSalt; // Salt used for CREATE2 deployments
    address registryBackupSigner; // Address of the backup signer
    string signatureModuleVersion; // Version of the signature module
    address relayerAdmin;
    DeployGasConfig gasConfig;
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

        _deployRegistry(
            networkOpts.protocolAdmin,
            networkOpts.deployerRelayerId,
            networkOpts.deploymentSalt,
            networkOpts.relayerAdmin,
            networkOpts.gasConfig
        );
        _deployRouter(
            networkOpts.protocolAdmin,
            networkOpts.deployerRelayerId,
            networkOpts.deploymentSalt,
            networkOpts.upgradeApprovalProcessId,
            networkOpts.gasConfig
        );
        _deploySignatureModule(
            networkOpts.protocolAdmin,
            networkOpts.deployerRelayerId,
            networkOpts.deploymentSalt,
            networkOpts.signatureModuleVersion,
            networkOpts.registryBackupSigner,
            networkOpts.gasConfig
        );
    }

    function _deployRegistry(
        address protocolAdmin,
        string memory relayerId,
        bytes32 salt,
        address relayerAdmin,
        DeployGasConfig memory gasConfig
    ) internal {
        DefenderOptions memory opts;
        TxOverrides memory txOverrides;

        txOverrides.gasLimit = 1_250_000;
        txOverrides.gasPrice = gasConfig.gasPrice;
        txOverrides.maxFeePerGas = gasConfig.maxFeePerGas;
        txOverrides.maxPriorityFeePerGas = gasConfig.maxPriorityFeePerGas;

        opts.useDefenderDeploy = true;
        opts.relayerId = relayerId;
        opts.salt = salt;
        opts.txOverrides = txOverrides;

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

    function _deployRouter(
        address protocolAdmin,
        string memory relayerId,
        bytes32 salt,
        string memory upgradeApprovalProcessId,
        DeployGasConfig memory gasConfig
    ) internal {
        // TODO: pass in registry address
        Options memory opts;
        TxOverrides memory txOverrides;

        txOverrides.gasLimit = 4_000_000;
        txOverrides.gasPrice = gasConfig.gasPrice;
        txOverrides.maxFeePerGas = gasConfig.maxFeePerGas;
        txOverrides.maxPriorityFeePerGas = gasConfig.maxPriorityFeePerGas;

        opts.defender.useDefenderDeploy = true;
        opts.defender.relayerId = relayerId;
        opts.defender.salt = salt;
        opts.defender.upgradeApprovalProcessId = upgradeApprovalProcessId;
        opts.defender.txOverrides = txOverrides;

        routerProxy = Upgrades.deployUUPSProxy(
            "Cube3RouterImpl.sol",
            abi.encodeCall(Cube3RouterImpl.initialize, (registry, protocolAdmin)),
            opts
        );

        console.log("Deployed Router Proxy contract to address", routerProxy);
    }

    function _deploySignatureModule(
        address protocolAdmin,
        string memory relayerId,
        bytes32 salt,
        string memory signatureModuleVersion,
        address backupSigner,
        DeployGasConfig memory gasConfig
    ) internal {
        if (routerProxy == address(0)) {
            revert("RouterProxy not deployed");
        }
        DefenderOptions memory opts;

        TxOverrides memory txOverrides;

        txOverrides.gasLimit = 1_500_000;
        txOverrides.gasPrice = gasConfig.gasPrice;
        txOverrides.maxFeePerGas = gasConfig.maxFeePerGas;
        txOverrides.maxPriorityFeePerGas = gasConfig.maxPriorityFeePerGas;

        opts.useDefenderDeploy = true;
        opts.relayerId = relayerId;
        opts.salt = salt;
        opts.txOverrides = txOverrides;

        registry = Defender.deployContract(
            "Cube3SignatureModule.sol",
            abi.encode(routerProxy, signatureModuleVersion, backupSigner),
            opts
        );
        console.log("Deployed Registry contract to address", registry);
    }
}
