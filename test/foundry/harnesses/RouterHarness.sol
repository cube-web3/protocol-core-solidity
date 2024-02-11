// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Cube3RouterImpl } from "../../../src/Cube3RouterImpl.sol";

import { Structs } from "../../../src/common/Structs.sol";

/// @notice Testing harness for the Cube3RouterImpl contract for exposing internal fuctions for testing.
contract RouterHarness is Cube3RouterImpl {
    /*//////////////////////////////////////////////////////////////
            STORAGE HELPERS
    //////////////////////////////////////////////////////////////*/

    function setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) public {
        _setFunctionProtectionStatus(integration, fnSelector, isEnabled);
    }

    function setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) public {
        _setIntegrationRegistrationStatus(integration, status);
    }

    function wrappedSetProtocolConfig(address registry, bool isPaused) public {
        _setProtocolConfig(registry, isPaused);
    }

    /*//////////////////////////////////////////////////////////////
            WRAPPED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function shouldBypassRouting(bytes4 integrationFnCallSelector) public returns (bool) {
        return _shouldBypassRouting(integrationFnCallSelector);
    }

    function executeModuleFunctionCall(address module, bytes calldata payload) public returns (bytes32) {
        return _executeModuleFunctionCall(module, payload);
    }
}
