// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { RouterStorage } from "../../../src/abstracts/RouterStorage.sol";

import { Structs } from "../../../src/common/Structs.sol";
/// @notice Testing harness for the RouterStorage contract for testing storage getters and setters.
/// @dev All getters have a visibility of `public`, so no need to wrap them.

contract RouterStorageHarness is RouterStorage {
    /*//////////////////////////////////////////////////////////////
        SETTERS
    //////////////////////////////////////////////////////////////*/

    function setProtocolConfig(address registry, bool isPaused) public {
        _setProtocolConfig(registry, isPaused);
    }

    function setPendingIntegrationAdmin(address integration, address pendingAdmin) public {
        _setPendingIntegrationAdmin(integration, pendingAdmin);
    }

    function setIntegrationAdmin(address integration, address newAdmin) public {
        _setIntegrationAdmin(integration, newAdmin);
    }

    function setFunctionProtectionStatus(address integration, bytes4 fnSelector, bool isEnabled) public {
        _setFunctionProtectionStatus(integration, fnSelector, isEnabled);
    }

    function setIntegrationRegistrationStatus(address integration, Structs.RegistrationStatus status) public {
        _setIntegrationRegistrationStatus(integration, status);
    }

    function setModuleInstalled(bytes16 moduleId, address moduleAddress, string memory version) public {
        _setModuleInstalled(moduleId, moduleAddress, version);
    }

    function setUsedRegistrationSignatureHash(bytes32 signatureHash) public {
        _setUsedRegistrationSignatureHash(signatureHash);
    }

    /*//////////////////////////////////////////////////////////////
        DELETE
    //////////////////////////////////////////////////////////////*/

    function deleteIntegrationPendingAdmin(address integration) public {
        _deleteIntegrationPendingAdmin(integration);
    }

    function deleteInstalledModule(bytes16 moduleId, address deprecatedModuleAddress, string memory version) public {
        _deleteInstalledModule(moduleId, deprecatedModuleAddress, version);
    }
}
