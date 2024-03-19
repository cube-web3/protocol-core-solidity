// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Cube3ProtectionUpgradeable} from "@cube3/upgradeable/Cube3ProtectionUpgradeable.sol";

contract DemoUpgradeableUUPS is Cube3ProtectionUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    bytes32 public state;

    event CalledSucceeded(bytes32 oldArg, bytes32 newArg);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address router, address admin, bool checkProtection) public initializer {
        // In this scenario, the contract owner is the same account as the integration's admin, which
        // has privileged access to the router.
        __Cube3ProtectionUpgradeable_init(router, admin, checkProtection);
        __Ownable_init(admin);
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function protectedFunction(bytes32 arg, bytes calldata cube3Payload) public cube3Protected(cube3Payload) {
        bytes32 oldArg = arg;
        state = arg;
        emit CalledSucceeded(oldArg, arg);
    }
}
