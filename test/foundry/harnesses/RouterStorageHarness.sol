// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { RouterStorage } from "../../../src/abstracts/RouterStorage.sol";

import { Structs } from "../../../src/common/Structs.sol";
/// @notice Testing harness for the RouterStorage contract for testing storage getters and setters.
/// @dev All getters have a visibility of `public`, so no need to wrap them.

contract RouterStorageHarness is RouterStorage {
    /*//////////////////////////////////////////////////////////////
        SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Fuzz
    function setProtocolConfig(address registry, bool isPaused) public {
        _setProtocolConfig(registry, isPaused);
    }

    /// @dev Fuzz
    function setPendingIntegrationAdmin(address integration, address currentAdmin, address pendingAdmin) public {
        _setPendingIntegrationAdmin(integration, currentAdmin, pendingAdmin);
    }

    function setIntegrationAdmin(address integration, address newAdmin) public {
        _setIntegrationAdmin(integration, newAdmin);
    }

    function setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) public {
        _setFunctionProtectionStatus(integration, fnSelector, isEnabled);
    }

    function setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatusEnum status) public {
        _setIntegrationRegistrationStatus(integration, status);
    }

    function setModuleInstalled(bytes16 moduleId, address moduleAddress, string memory version) public {
        _setModuleInstalled(moduleId, moduleAddress, version);
    }

    function setUsedRegistrationSignatureHash(bytes32 signatureHash) public {
        _setUsedRegistrationSignatureHash(signatureHash);
    }

    function setModuleVersionDeprecated(bytes16 moduleId, string memory version) public {
        _setModuleVersionDeprecated(moduleId, version);
    }

    /*//////////////////////////////////////////////////////////////
        DELETE
    //////////////////////////////////////////////////////////////*/

    function deleteIntegrationPendingAdmin(address integration) public {
        _deleteIntegrationPendingAdmin(integration);
    }

    function deleteInstalledModule(bytes16 moduleId) public {
        _deleteInstalledModule(moduleId);
    }
}
