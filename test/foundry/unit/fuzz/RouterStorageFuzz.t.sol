// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "../../../../src/common/Structs.sol";
import { RouterStorageHarness } from "../../harnesses/RouterStorageHarness.sol";

contract RouterStorage_Fuzz_Unit_Test is BaseTest {
    uint256 constant HALF_MAX_UINT = type(uint256).max / 2;

    function setUp() public {
        // BaseTest.setUp();
        // initProtocol();
        _deployTestingContracts();
    }

    // Setting the protocol config succeeds and emits the correct event
    function testFuzz_SucceedsWhen_ProtocolConfigIsSet(uint256 addressSeed, uint256 flagValue) public {
        addressSeed = bound(addressSeed, 1, 1 + HALF_MAX_UINT);
        address registry = vm.addr(addressSeed);
        bool flag = flagValue % 2 == 0;

        // set the config
        vm.expectEmit(true, true, true, true);
        emit ProtocolConfigUpdated(registry, flag);
        routerStorageHarness.setProtocolConfig(registry, flag);

        // check the config values
        assertEq(registry, routerStorageHarness.getProtocolConfig().registry, "registry mismatch");
        assertEq(flag, routerStorageHarness.getProtocolConfig().paused, "paused mismatch");
    }

    // Setting the pending integration admin succeeds and emits the correct event
    // Deleting the pending integration admin succeeds and emits the correct event
    function testFuzz_SucceedsWhen_PendingIntegrationAdminIsSet(uint256 addressSeed, uint256 addressSeed2) public {
        addressSeed = bound(addressSeed, 1, 1 + HALF_MAX_UINT);
        addressSeed2 = bound(addressSeed2, 1, 1 + HALF_MAX_UINT);
        vm.assume(addressSeed != addressSeed2);

        address currentAdmin = _randomAddress();
        address integration = vm.addr(addressSeed);
        address pendingAdmin = vm.addr(addressSeed2);

        vm.startPrank(currentAdmin);
        // set the pending admin
        vm.expectEmit(true, true, true, true);
        emit IntegrationAdminTransferStarted(integration, currentAdmin, pendingAdmin);
        routerStorageHarness.setPendingIntegrationAdmin(integration, currentAdmin, pendingAdmin);

        vm.stopPrank();

        // check the pending admin
        assertEq(pendingAdmin, routerStorageHarness.getIntegrationPendingAdmin(integration), "pending admin mismatch");

        // delete the pending admin
        vm.expectEmit(true, true, true, true);
        emit IntegrationPendingAdminRemoved(integration, pendingAdmin);
        routerStorageHarness.deleteIntegrationPendingAdmin(integration);
        assertEq(address(0), routerStorageHarness.getIntegrationPendingAdmin(integration), "pending admin mismatch");
    }

    // setting the integration admin succeeds and emits the correct event
    function testFuzz_SucceedsWhen_SettingIntegrationAdmin(uint256 addressSeed, uint256 addressSeed2) public {
        addressSeed = bound(addressSeed, 1, 1 + HALF_MAX_UINT);
        addressSeed2 = bound(addressSeed2, 1, 1 + HALF_MAX_UINT);
        vm.assume(addressSeed != addressSeed2);

        address integration = vm.addr(addressSeed);
        address newAdmin = vm.addr(addressSeed2);

        // setting the integration admin for the first time should set it from the zero address
        address currentAdmin = routerStorageHarness.getIntegrationAdmin(integration);
        assertEq(currentAdmin, address(0), "admin mismatch");

        vm.expectEmit(true, true, true, true);
        emit IntegrationAdminTransferred(integration, currentAdmin, newAdmin);
        routerStorageHarness.setIntegrationAdmin(integration, newAdmin);

        vm.roll(1);

        // check the admin
        assertEq(newAdmin, routerStorageHarness.getIntegrationAdmin(integration), "new admin mismatch");

        // setting the admin again should replace the current admin
        currentAdmin = routerStorageHarness.getIntegrationAdmin(integration);
        address futureAdmin = _randomAddress();

        vm.expectEmit(true, true, true, true);
        emit IntegrationAdminTransferred(integration, currentAdmin, futureAdmin);
        routerStorageHarness.setIntegrationAdmin(integration, futureAdmin);

        // check the admin again
        assertEq(futureAdmin, routerStorageHarness.getIntegrationAdmin(integration), "future admin mismatch");
    }

    // Setting function protection status succeeds and emits the correct event
    function testFuzz_SucceedsWhen_SettingFnProtectionStatus(
        uint256 integrationSeed,
        uint256 selectorSeed,
        uint256 flagSeed
    )
        public
    {
        integrationSeed = bound(integrationSeed, 1, 1 + HALF_MAX_UINT);
        selectorSeed = bound(selectorSeed, 1, 1 + HALF_MAX_UINT);
        address integration = vm.addr(integrationSeed);
        bool flag = flagSeed % 2 == 0;
        bytes4 selector = bytes4(bytes32(selectorSeed));

        vm.expectEmit(true, true, true, true);
        emit FunctionProtectionStatusUpdated(integration, selector, flag);
        routerStorageHarness.setFunctionProtectionStatus(integration, selector, flag);

        assertEq(
            flag, routerStorageHarness.getIsIntegrationFunctionProtected(integration, selector), "protection mismatch"
        );

        vm.expectEmit(true, true, true, true);
        emit FunctionProtectionStatusUpdated(integration, selector, !flag);
        routerStorageHarness.setFunctionProtectionStatus(integration, selector, !flag);

        assertEq(
            !flag, routerStorageHarness.getIsIntegrationFunctionProtected(integration, selector), "protection mismatch"
        );
    }

    // Setting integration registration status succeeds and emits correct event
    function testFuzz_SucceedsWhen_IntegrationRegistrationStatusSet() public {
        address integration = _randomAddress();

        // unitialized status should be UNREGISTERED
        assertEq(
            uint256(Structs.RegistrationStatusEnum.UNREGISTERED),
            uint256(routerStorageHarness.getIntegrationStatus(integration)),
            "status mismatch"
        );

        Structs.RegistrationStatusEnum status = Structs.RegistrationStatusEnum.PENDING;

        // set the status to PENDING
        vm.expectEmit(true, true, true, true);
        emit IntegrationRegistrationStatusUpdated(integration, status);
        routerStorageHarness.setIntegrationRegistrationStatus(integration, status);
        assertEq(uint256(status), uint256(routerStorageHarness.getIntegrationStatus(integration)), "status mismatch");

        // set the status to REGISTERED
        status = Structs.RegistrationStatusEnum.REGISTERED;
        vm.expectEmit(true, true, true, true);
        emit IntegrationRegistrationStatusUpdated(integration, status);
        routerStorageHarness.setIntegrationRegistrationStatus(integration, status);
        assertEq(
            uint256(Structs.RegistrationStatusEnum.REGISTERED),
            uint256(routerStorageHarness.getIntegrationStatus(integration)),
            "status mismatch"
        );

        // set the status to REVOKED
        status = Structs.RegistrationStatusEnum.REVOKED;
        vm.expectEmit(true, true, true, true);
        emit IntegrationRegistrationStatusUpdated(integration, status);
        routerStorageHarness.setIntegrationRegistrationStatus(integration, status);
        assertEq(
            uint256(Structs.RegistrationStatusEnum.REVOKED),
            uint256(routerStorageHarness.getIntegrationStatus(integration)),
            "status mismatch"
        );
    }

    // Installing a module succeeds and emits the correct event
    // Deleting a module succeeds and emits the correct event
    function testFuzz_SucceedsWhen_ModuleInstalled(
        uint256 moduleIdSeed,
        uint256 addressSeed,
        uint256 versionSeed
    )
        public
    {
        moduleIdSeed = bound(moduleIdSeed, 1, 1 + HALF_MAX_UINT);
        addressSeed = bound(addressSeed, 1, 1 + HALF_MAX_UINT);
        versionSeed = bound(versionSeed, 1, 1 + HALF_MAX_UINT);

        bytes16 moduleId = bytes16(bytes32(moduleIdSeed));
        address moduleAddress = vm.addr(addressSeed);
        string memory version = "moduleVersion-0.0.1";

        // install the module
        vm.expectEmit(true, true, true, true);
        emit RouterModuleInstalled(moduleId, moduleAddress, version);
        routerStorageHarness.setModuleInstalled(moduleId, moduleAddress, version);
        assertEq(moduleAddress, routerStorageHarness.getModuleAddressById(moduleId), "module address mismatch");

        // delete the module
        vm.expectEmit(true, true, true, true);
        emit RouterModuleDeprecated(moduleId, moduleAddress, version);
        routerStorageHarness.deleteInstalledModule(moduleId, moduleAddress, version);
        assertEq(address(0), routerStorageHarness.getModuleAddressById(moduleId), "module address mismatch");
    }

    // Setting the used registration signature hash succeeds and emits the correct event
    function testFuzz_SucceedsWhen_UsedRegistrationSignatureHashSet(uint256 hashSeed) public {
        bytes32 signatureHash = bytes32(hashSeed);
        assertFalse(routerStorageHarness.getRegistrarSignatureHashExists(signatureHash), "hash mismatch");
        vm.expectEmit(true, true, true, true);
        emit UsedRegistrationSignatureHash(signatureHash);
        routerStorageHarness.setUsedRegistrationSignatureHash(signatureHash);
        assertTrue(routerStorageHarness.getRegistrarSignatureHashExists(signatureHash), "hash mismatch");
    }
}
