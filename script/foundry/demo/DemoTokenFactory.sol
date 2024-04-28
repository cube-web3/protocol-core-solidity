// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {DemoTokenImpl} from "./DemoTokenImpl.sol";

contract DemoTokenFactory {
    using Clones for address;

    address public immutable router;

    address public immutable tokenTemplate = address(new DemoTokenImpl());

    event TokenDeployed(address indexed tokenAddress, string tokenName, string tokenSymbol);
    constructor(address _router) {
        if (_router == address(0)) {
            revert("Invalid router");
        }
        router = _router;
    }

    /// @notice Deploys a new minimal proxy using the token template.
    function deployToken(string calldata tokenName, string calldata tokenSymbol) public {
        address token = tokenTemplate.clone();
        DemoTokenImpl(payable(token)).initialize(
            router,
            msg.sender, // protection admin
            true, // enable protection
            tokenName,
            tokenSymbol
        );

        emit TokenDeployed(token, tokenName, tokenSymbol);
    }
}
