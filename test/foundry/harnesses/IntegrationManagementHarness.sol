// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Structs } from "../../../src/common/Structs.sol";
import { IntegrationManagement } from "../../../src/abstracts/IntegrationManagement.sol";

/// @notice Testing harness for the IntegrationManagement contract, exposing internal functions for testing
contract IntegrationManagementHarness is IntegrationManagement {
    // public/external functions are exposed by the IntegrationManagement contract
    // are not overridden here

    function setIntegrationAdmin(address integration, address admin) public {
        _setIntegrationAdmin(integration, admin);
    }

    function setIntegrationPendingAdmin(address integration, address currentAdmin, address pendingAdmin) public {
        _setPendingIntegrationAdmin(integration, currentAdmin, pendingAdmin);
    }

    function IntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) public {
        _setIntegrationRegistrationStatus(integration, status);
    }

    function setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) public {
        _updateIntegrationRegistrationStatus(integration, status);
    }
}
