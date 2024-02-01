// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ProtocolManagement } from "../../../src/abstracts/ProtocolManagement.sol";

/// @notice Testing harness for the ProtocolManagement contract.
/// @dev All functionality is already exposed externally, so no need to wrap anything.
/// @dev Serves as a mock router from the mock module's persepective.
contract ProtocolManagementHarness is ProtocolManagement {
    /*
    The following functions are exposed externall by ProtocolManagement:
    - setProtocolConfig
    - callModuleFunctionAsAdmin
    - installModule
    - deprecateModule

    Event emission is not tested here, but in the unit tests for the setter functions.
    */

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
