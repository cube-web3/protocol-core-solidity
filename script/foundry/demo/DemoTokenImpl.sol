// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Cube3ProtectionUpgradeable} from "@cube3/upgradeable/Cube3ProtectionUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract DemoTokenImpl is Cube3ProtectionUpgradeable, ERC20Upgradeable {
    address public owner;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address router,
        address admin,
        bool checkProtection,
        string memory tokenName,
        string memory tokenSymbol
    ) public initializer {
        owner = admin;
        // In this scenario, the contract owner is the same account as the integration's admin, which
        // has privileged access to the router.
        __Cube3ProtectionUpgradeable_init(router, admin, checkProtection);
        __ERC20_init(tokenName, tokenSymbol);
    }

    function mint(address to, uint256 amount, bytes calldata cube3Payload) public cube3Protected(cube3Payload) {
        if (msg.sender != owner) {
            revert("DemoImpl: only owner can mint");
        }

        _mint(to, amount);
    }

    function updateCube3Connection(bool useCube3) external {
        if (msg.sender != owner) {
            revert("DemoImpl: only owner can update connection");
        }
        _updateShouldUseProtocol(useCube3);
    }
}
