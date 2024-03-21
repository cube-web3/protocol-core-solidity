// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Structs} from "@src/common/Structs.sol";
import {IntegrationManagement} from "@src/abstracts/IntegrationManagement.sol";

/// @notice Testing harness for the IntegrationManagement contract, exposing internal functions for testing
contract IntegrationManagementHarness is IntegrationManagement {
    constructor() {
        // allow the test suite to assign roles as needed
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setIntegrationAdmin(address integration, address admin) public {
        _setIntegrationAdmin(integration, admin);
    }

    function setPendingIntegrationAdmin(address integration, address pendingAdmin) public {
        _setPendingIntegrationAdmin(integration, pendingAdmin);
    }

    function setUsedRegistrationSignatureHash(bytes32 sigHash) public {
        _setUsedRegistrationSignatureHash(sigHash);
    }

    function updateProtocolConfig(address registry, bool isPaused) public {
        _updateProtocolConfig(registry, isPaused);
    }

    function setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) public {
        _updateIntegrationRegistrationStatus(integration, status);
    }

    function wrappedUpdateIntegrationRegistrationStatus(
        address integration,
        Structs.RegistrationStatusEnum status
    ) public {
        _updateIntegrationRegistrationStatus(integration, status);
    }
}
