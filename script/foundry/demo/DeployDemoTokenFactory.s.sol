// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {console} from "forge-std/console.sol";

import {DeployUtils} from "../utils/DeployUtils.sol";

import {DemoTokenFactory} from "./DemoTokenFactory.sol";

contract DeployDemoTokenFactory is Script, DeployUtils {
    uint256 internal V2_DEPLOYER_SEPOLIA_PVT_KEY;
    address deployerV2;

    address internal constant DEPLOYED_ROUTER_PROXY = 0x84C4dCc09d6d713a1C81B55b1bb5b402E8dC98A4;

    function setUp() public {
        V2_DEPLOYER_SEPOLIA_PVT_KEY = vm.envUint("V2_DEPLOYER_SEPOLIA_PVT_KEY");
        deployerV2 = vm.addr(V2_DEPLOYER_SEPOLIA_PVT_KEY);
    }
    function run() public {
        vm.startBroadcast(V2_DEPLOYER_SEPOLIA_PVT_KEY);
        DemoTokenFactory factory = new DemoTokenFactory(DEPLOYED_ROUTER_PROXY);

        console.log("DemoFactory deployed to", address(factory));
        vm.stopBroadcast();
    }
}
