// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "../../../../src/common/Structs.sol";

import { IntegrationManagement } from "../../../../src/abstracts/IntegrationManagement.sol";

import { IntegrationManagementHarness } from "../../harnesses/IntegrationManagementHarness.sol";

contract IntegrationManagement_Concrete_Unit_Test is BaseTest {
    IntegrationManagementHarness integrationManagementHarness;

    function setUp() public {
        integrationManagementHarness = new IntegrationManagementHarness();
    }

    /*//////////////////////////////////////////////////////////////
           transferIntegrationAdmin
    //////////////////////////////////////////////////////////////*/

    // succeeds initiating admin transfer as integration admin
    function test_SucceedsWhen_TransferringIntegrationAdmin_AsAdmin() public {
        address integration = _randomAddress();
        address currentAdmin = _randomAddress();
        address newAdmin = _randomAddress();
        assertNotEq(currentAdmin, newAdmin, "admins match");

        integrationManagementHarness.setIntegrationAdmin(integration, currentAdmin);

        vm.startPrank(currentAdmin);
        vm.expectEmit(true, true, true, true);
        emit IntegrationAdminTransferStarted(integration, currentAdmin, newAdmin);
        integrationManagementHarness.transferIntegrationAdmin(integration, newAdmin);
        vm.stopPrank();
    }

    // fails initiating admin transfer as non admin
    function test_RevertsWhen_TransferringIntegrationAdmin_AsNonAdmin() public {
        address integration = _randomAddress();
        address currentAdmin = _randomAddress();
        address newAdmin = _randomAddress();
        assertNotEq(currentAdmin, newAdmin, "admins match");

        integrationManagementHarness.setIntegrationAdmin(integration, currentAdmin);

        address nonAdmin = _randomAddress();
        vm.startPrank(nonAdmin);
        vm.expectRevert(bytes("TODO: Not admin"));
        integrationManagementHarness.transferIntegrationAdmin(integration, nonAdmin);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           acceptIntegrationAdmin
    //////////////////////////////////////////////////////////////*/

    // succeeds accepting integration admin as pending admin and deleting the pending admin
    function test_Succeeds_AcceptingIntegrationAdmin_AsPendingAdmin(uint256 integrationSeed) public {
        address integration = _randomAddress();
        address pendingAdmin = _randomAddress();

        integrationManagementHarness.setIntegrationPendingAdmin(integration, address(0), pendingAdmin);

        vm.startPrank(pendingAdmin);
        vm.expectEmit(true, true, true, true);
        emit IntegrationAdminTransferred(integration, address(0), pendingAdmin);
        integrationManagementHarness.acceptIntegrationAdmin(integration);

        // confirm the deletion succeeded
        assertEq(
            address(0),
            integrationManagementHarness.getIntegrationPendingAdmin(integration),
            "pending admin not deleted"
        );
    }

    // fails accepting integration admin as non pending admin
    function test_RevertsWhen_AcceptingIntegrationAdmin_AsNonPendingAdmin() public {
        address integration = _randomAddress();
        address pendingAdmin = _randomAddress();

        integrationManagementHarness.setIntegrationPendingAdmin(integration, address(0), pendingAdmin);

        address nonPendingAdmin = _randomAddress();
        vm.startPrank(nonPendingAdmin);
        vm.expectRevert(bytes("TODO: Not pending admin"));
        integrationManagementHarness.acceptIntegrationAdmin(integration);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           updateFunctionProtectionStatus
    //////////////////////////////////////////////////////////////*/

    // fails updating function protection status as non admin
    function test_RevertsWhen_UpdatingFunctionProtectionStatus_AsNonAdmin() public {
        address integration = _randomAddress();
        address admin = _randomAddress();
        assertNotEq(integration, admin, "integration and admin match");

        // set the integration admin
        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](0);
        vm.startPrank(_randomAddress());
        vm.expectRevert(bytes("TODO: Not admin"));
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();
    }

    // fails updating function protection status for unregistered integration
    function test_RevertsWhen_UpdatingProtectionStatusForUnregisteredIntegration_AsAdmin() public {
        address integration = _randomAddress();
        address admin = _randomAddress();
        assertNotEq(integration, admin, "integration and admin match");

        // set the integration admin
        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        // set the integration registration status
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration, Structs.RegistrationStatusEnum.PENDING
        );

        Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](0);
        vm.startPrank(admin);
        vm.expectRevert(bytes("TODO: NotRegistered"));
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();
    }

    // fails setting function protection to true when registration is revoked

    /*//////////////////////////////////////////////////////////////
           updateIntegrationRegistrationStatus
    //////////////////////////////////////////////////////////////*/

    /*
    // succeeds updating integration registration status
    function test_SucceedsWhen_UpdatingIntegrationRegistrationStatus() public {
    address integration = _randomAddress();
    Structs.RegistrationStatusEnum status = Structs.RegistrationStatusEnum.Registered;

    vm.expectEmit(true,true,true,true);
    emit IntegrationRegistrationStatusUpdated(integration, status);
    integrationManagementHarness.updateIntegrationRegistrationStatus(integration, status);
    }

    // fails updating integration registration status when integration is not registered
    function test_RevertsWhen_UpdatingIntegrationRegistrationStatus_WhenNotRegistered() public {
    address integration = _randomAddress();
    Structs.RegistrationStatusEnum status = Structs.RegistrationStatusEnum.Registered;

    vm.expectRevert(bytes("TODO: Not registered"));
    integrationManagementHarness.updateIntegrationRegistrationStatus(integration, status);
    }
    */
}
