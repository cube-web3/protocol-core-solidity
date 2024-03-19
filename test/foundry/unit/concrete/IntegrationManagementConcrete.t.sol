// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.24;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

import {BaseTest} from "@test/foundry/BaseTest.t.sol";
import {Structs} from "@src/common/Structs.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IntegrationManagement} from "@src/abstracts/IntegrationManagement.sol";

import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";

import {IntegrationManagementHarness} from "@test/foundry/harnesses/IntegrationManagementHarness.sol";

contract IntegrationManagement_Concrete_Unit_Test is BaseTest {
    IntegrationManagementHarness integrationManagementHarness;

    function setUp() public override {
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
        vm.expectRevert(bytes(abi.encodeWithSelector(ProtocolErrors.Cube3Router_CallerNotIntegrationAdmin.selector)));
        integrationManagementHarness.transferIntegrationAdmin(integration, nonAdmin);
        vm.stopPrank();
    }

    // fails when transferring admin and the protocol is paused
    function test_RevertsWhen_TransferringIngrationAdmin_WhilePaused() public {
        address admin = _randomAddress();
        address integration = _randomAddress();
        address registry = _randomAddress();
        integrationManagementHarness.setIntegrationAdmin(integration, admin);

        // pause the protocol
        integrationManagementHarness.updateProtocolConfig(registry, true);

        vm.startPrank(admin);
        vm.expectRevert(bytes(abi.encodeWithSelector(ProtocolErrors.Cube3Router_ProtocolPaused.selector)));
        integrationManagementHarness.transferIntegrationAdmin(integration, _randomAddress());
        vm.stopPrank();
    }

    // fails when accepting admin transfer while paused
    function test_RevertsWhen_AcceptingIntegrationAdmin_WhilePaused() public {
        address admin = _randomAddress();
        address newAdmin = _randomAddress();
        address integration = _randomAddress();
        address registry = _randomAddress();
        integrationManagementHarness.setIntegrationAdmin(integration, admin);

        vm.startPrank(admin);
        integrationManagementHarness.transferIntegrationAdmin(integration, newAdmin);
        vm.stopPrank();
        assertEq(
            newAdmin,
            integrationManagementHarness.getIntegrationPendingAdmin(integration),
            "pending admin not set"
        );

        integrationManagementHarness.updateProtocolConfig(registry, true);

        vm.startPrank(newAdmin);
        vm.expectRevert(bytes(abi.encodeWithSelector(ProtocolErrors.Cube3Router_ProtocolPaused.selector)));
        integrationManagementHarness.acceptIntegrationAdmin(integration);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           acceptIntegrationAdmin
    //////////////////////////////////////////////////////////////*/

    // succeeds accepting integration admin as pending admin and deleting the pending admin
    function test_Succeeds_AcceptingIntegrationAdmin_AsPendingAdmin() public {
        address integration = _randomAddress();
        address pendingAdmin = _randomAddress();

        integrationManagementHarness.setPendingIntegrationAdmin(integration, pendingAdmin);

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

        integrationManagementHarness.setPendingIntegrationAdmin(integration, pendingAdmin);

        address nonPendingAdmin = _randomAddress();
        vm.startPrank(nonPendingAdmin);
        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Router_CallerNotPendingIntegrationAdmin.selector));
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
        vm.expectRevert(bytes(abi.encodeWithSelector(ProtocolErrors.Cube3Router_CallerNotIntegrationAdmin.selector)));
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
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );

        Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](0);
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_IntegrationRegistrationNotComplete.selector);
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           initiateIntegrationRegistration
    //////////////////////////////////////////////////////////////*/

    // fails if admin address is zero
    function test_RevertsWhen_AdminAddressIsZeroAddress() public {
        address admin = address(0);
        vm.expectRevert(ProtocolErrors.Cube3Router_InvalidIntegrationAdmin.selector);
        integrationManagementHarness.initiateIntegrationRegistration(admin);
    }

    // fails if integration already has an admin
    function test_RevertsWhen_AdminExistsForIntegration() public {
        address integration = _randomAddress();
        address admin = _randomAddress();

        integrationManagementHarness.setIntegrationAdmin(integration, admin);

        vm.startPrank(integration);
        vm.expectRevert(ProtocolErrors.Cube3Router_IntegrationAdminAlreadyInitialized.selector);
        integrationManagementHarness.initiateIntegrationRegistration(admin);
        vm.stopPrank();
    }

    // succeeds initiating integration registration as a new admin
    function test_Succeeds_InitiatingRegistrationWithAdmin() public {
        address admin = _randomAddress();
        address integration = _randomAddress();
        assertNotEq(integration, admin, "integration and admin match");

        vm.startPrank(integration);
        vm.expectEmit(true, true, true, true);
        emit IntegrationAdminTransferred(integration, address(0), admin);
        emit IntegrationRegistrationStatusUpdated(integration, Structs.RegistrationStatusEnum.PENDING);
        integrationManagementHarness.initiateIntegrationRegistration(admin);
        vm.stopPrank();

        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        assertEq(
            uint256(Structs.RegistrationStatusEnum.PENDING),
            uint256(integrationManagementHarness.getIntegrationStatus(integration)),
            "status not set"
        );
    }

    /*//////////////////////////////////////////////////////////////
          batchUpdateIntegrationRegistrationStatus
    //////////////////////////////////////////////////////////////*/

    // fails if not called by CUBE3_INTEGRATION_MANAGER_ROLE
    function test_RevertsWhen_BatchUpdatingRegistrations_AsNonAdmin() public {
        address[] memory integrations = new address[](1);
        integrations[0] = _randomAddress();
        Structs.RegistrationStatusEnum[] memory statuses = new Structs.RegistrationStatusEnum[](1);
        statuses[0] = Structs.RegistrationStatusEnum.REGISTERED;

        address account = _randomAddress();
        vm.startPrank(account);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                account,
                CUBE3_INTEGRATION_MANAGER_ROLE
            )
        );
        integrationManagementHarness.batchUpdateIntegrationRegistrationStatus(integrations, statuses);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
          updateIntegrationRegistrationStatus
    //////////////////////////////////////////////////////////////*/

    // fails updating integration registration status without correct role
    function test_RevertsWhen_UpdatingIntegrationRegistration_AsNonIntegrationManager() public {
        address account = _randomAddress();
        vm.startPrank(account);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                account,
                CUBE3_INTEGRATION_MANAGER_ROLE
            )
        );
        integrationManagementHarness.updateIntegrationRegistrationStatus(
            _randomAddress(),
            Structs.RegistrationStatusEnum.REGISTERED
        );
        vm.stopPrank();
    }

    // succeeds updating integration registration status with correct role and emits correct event
    function test_SucceedsWhen_UpdatingIntegrationRegistrationStatus_AsIntegrationManager() public {
        integrationManagementHarness.grantRole(CUBE3_INTEGRATION_MANAGER_ROLE, cube3Accounts.integrationManager);

        address integration = _randomAddress();
        vm.startPrank(cube3Accounts.integrationManager);
        vm.expectEmit(true, true, true, true);
        emit IntegrationRegistrationStatusUpdated(integration, Structs.RegistrationStatusEnum.REGISTERED);
        integrationManagementHarness.updateIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.REGISTERED
        );
    }

    /*//////////////////////////////////////////////////////////////
           _updateIntegrationRegistrationStatus
    //////////////////////////////////////////////////////////////*/

    // fails if the integration is the zero address
    function test_RevertsWhen_IntegrationAddressIsZeroAddress() public {
        vm.expectRevert(ProtocolErrors.Cube3Protocol_InvalidIntegration.selector);
        integrationManagementHarness.wrappedUpdateIntegrationRegistrationStatus(
            address(0),
            Structs.RegistrationStatusEnum.REGISTERED
        );
    }
}
