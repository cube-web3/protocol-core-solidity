// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ProtocolManagement} from "@src/abstracts/ProtocolManagement.sol";

/// @notice Testing harness for the ProtocolManagement contract.
/// @dev All functionality is already exposed externally, so no need to wrap anything.
/// @dev Serves as a mock router from the mock module's persepective.
contract ProtocolManagementHarness is ProtocolManagement {
    /*
    The following functions are exposed externally by ProtocolManagement:
    - updateProtocolConfig
    - callModuleFunctionAsAdmin
    - installModule
    - deprecateModule

    Event emission is not tested here, but in the unit tests for the setter functions.
    */

    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function setModuleInstalled(bytes16 moduleId, address module, string memory version) external {
        _setModuleInstalled(moduleId, module, version);
    }
}
