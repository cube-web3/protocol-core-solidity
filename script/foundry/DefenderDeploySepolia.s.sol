// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {DefenderDeploy, NetworkDeploymentDetails, DeployGasConfig} from "./utils/DefenderDeploy.sol";

contract DefenderDeploySepolia is DefenderDeploy {
    NetworkDeploymentDetails opts;
    DeployGasConfig gasConfig;
    function setUp() public override {
        gasConfig = DeployGasConfig({
            gasPrice: 1_500_000_000, // 1.5 gwei
            maxFeePerGas: 1_500_000_000, // 1.5 gwei
            maxPriorityFeePerGas: 1_500_000_000 // 1.5 gwei
        });
        opts = NetworkDeploymentDetails({
            deployerRelayerId: "2bfac9a1-9830-4e3f-8059-1501b253a2b5", // Sepolia Deployer Relayer
            upgradeApprovalProcessId: "b294df0c-3320-4352-a526-40d59629ab72",
            deploymentSalt: keccak256(abi.encode("sepolia-15")),
            registryBackupSigner: 0x0f9F153454E08cE185E555C0dc3c034C5f66dd77,
            signatureModuleVersion: "signature-0.0.1",
            relayerAdmin: 0x760c379198d95a449596e9aC92330319E17359D1,
            gasConfig: gasConfig
        });
    }

    function run() public {
        super.run(opts);
    }
}
