// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ICube3Registry } from "@src/interfaces/ICube3Registry.sol";
import { ICube3RouterImpl } from "@src/interfaces/ICube3RouterImpl.sol";
import { IIntegrationManagement } from "@src/interfaces/IIntegrationManagement.sol";
import { IProtocolManagement } from "@src/interfaces/IProtocolManagement.sol";
import { IRouterStorage } from "@src/interfaces/IRouterStorage.sol";

/// @title ICube3Router
/// @notice Interface wrapping all the abstract contracts that make up the CUBE3 Router.
/// @dev Not inherited by any contract.
/// @dev Provides a convenient unified interface when making external calls to the Router.
interface ICube3Router is
    ICube3Registry,
    ICube3RouterImpl,
    IIntegrationManagement,
    IProtocolManagement,
    IRouterStorage
{ }