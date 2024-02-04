// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Structs } from "../../../src/common/Structs.sol";
import { IntegrationManagement } from "../../../src/abstracts/IntegrationManagement.sol";

/// @notice Testing harness for the IntegrationManagement contract, exposing internal functions for testing
contract IntegrationManagementHarness is IntegrationManagement {
    constructor() {
        // allow the test suite to assign roles as needed
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
    // public/external functions exposed by the IntegrationManagement contract
    // are not overridden here

    function setIntegrationAdmin(address integration, address admin) public {
        _setIntegrationAdmin(integration, admin);
    }

    function setIntegrationPendingAdmin(address integration, address currentAdmin, address pendingAdmin) public {
        _setPendingIntegrationAdmin(integration, currentAdmin, pendingAdmin);
    }

    function setUsedRegistrationSignatureHash(bytes32 sigHash) public {
        _setUsedRegistrationSignatureHash(sigHash);
    }

    function setProtocolConfig(address registry, bool isPaused) public {
        _setProtocolConfig(registry, isPaused);
    }

    function setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) public {
        _updateIntegrationRegistrationStatus(integration, status);
    }

    function wrappedUpdateIntegrationRegistrationStatus(
        address integration,
        Structs.RegistrationStatusEnum status
    )
        public
    {
        _updateIntegrationRegistrationStatus(integration, status);
    }
}
