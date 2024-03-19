// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {SecurityModuleBase} from "@src/modules/SecurityModuleBase.sol";
import {TestEvents} from "@test/utils/TestEvents.t.sol";

/// @notice Mock module for testing interactions via the Router.
contract MockModule is SecurityModuleBase, TestEvents {
    bytes32 public constant SUCCESSFUL_RETURN = keccak256("SUCCESSFUL_RETURN");

    // flag for forcing deprecation to fail
    bool public preventDeprecation = false;

    // flag for forcing module function call to revert
    bool public forceRevert = false;

    constructor(address mockRouter, string memory version) SecurityModuleBase(mockRouter, version) {}
    function updateForceRevert(bool shouldRevert) public {
        forceRevert = shouldRevert;
    }

    /// @notice emulates a module's core functionality that optionally reverts
    function executeMockModuleFunction(bytes32 randomHash) public onlyCube3Router returns (bytes32) {
        if (forceRevert) {
            revert("Forced Revert");
        }
        emit MockModuleCallSucceededWithArgs(randomHash);
        return MODULE_CALL_SUCCEEDED;
    }

    /// @notice emulates a module's core functionality that returns the incorrect amount of data
    function executeMockModuleFunctionInvalidReturnDataLength(
        bytes32 randomHash
    ) public view onlyCube3Router returns (bytes32, bool) {
        (randomHash);
        return (MODULE_CALL_SUCCEEDED, true);
    }

    /// @notice emulates a module's core functionality that returns the incorrect type of data
    function executeMockModuleFunctionInvalidReturnDataType(
        bytes32 randomHash
    ) public view onlyCube3Router returns (bytes32) {
        (randomHash);
        return keccak256(abi.encode(MODULE_CALL_SUCCEEDED));
    }

    function updatePreventDeprecation(bool shouldPreventDeprecation) public {
        preventDeprecation = shouldPreventDeprecation;
    }

    function privilegedPayableFunction() external payable onlyCube3Router {
        require(msg.value > 0, "no value sent");
        emit MockModuleCallSucceeded();
    }

    function privilegedFunctionWithArgs(bytes32 arg) external onlyCube3Router returns (bytes32) {
        emit MockModuleCallSucceededWithArgs(arg);
        return arg;
    }

    function privilegedFunction() external onlyCube3Router returns (bytes32) {
        emit MockModuleCallSucceeded();
        return SUCCESSFUL_RETURN;
    }

    function privilegedFunctionThatReverts() external view onlyCube3Router {
        revert("FAILED");
    }

    function deprecate() public view override returns (string memory) {
        if (preventDeprecation) {
            revert("deprecation failed");
        }

        return (moduleVersion);
    }
}

/// @dev Custom module that overrides the deprecate function
contract MockModuleCustomDeprecate is SecurityModuleBase {
    event CustomDeprecation();
    constructor(address mockRouter, string memory version) SecurityModuleBase(mockRouter, version) {}
    function deprecate() public override returns (string memory) {
        super.deprecate();
        emit CustomDeprecation();
        return "custom deprecation";
    }
}
