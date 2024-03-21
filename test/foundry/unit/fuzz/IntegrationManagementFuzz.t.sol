// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {BaseTest} from "@test/foundry/BaseTest.t.sol";
import {Structs} from "@src/common/Structs.sol";

import {IntegrationManagement} from "@src/abstracts/IntegrationManagement.sol";

import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";
import {MockTarget} from "@test/mocks/MockContract.t.sol";
import {MockRegistry} from "@test/mocks/MockRegistry.t.sol";
import {IntegrationManagementHarness} from "@test/foundry/harnesses/IntegrationManagementHarness.sol";
import {PayloadCreationUtils} from "@test/libs/PayloadCreationUtils.sol";

contract IntegrationManagement_Fuzz_Unit_Test is BaseTest {
    IntegrationManagementHarness integrationManagementHarness;
    MockRegistry mockRegistry;

    function setUp() public override {
        _createCube3Accounts();
        integrationManagementHarness = new IntegrationManagementHarness();
        mockRegistry = new MockRegistry();
    }

    /*//////////////////////////////////////////////////////////////
           updateFunctionProtectionStatus
    //////////////////////////////////////////////////////////////*/

    // succeeds updating function protection status as admin for registered integration
    function testFuzz_SucceedsWhen_UpdatingFunctionProtectionStatus_AsIntegrationAdmin(
        uint256 numSelectors,
        uint256 selectorSeed
    ) public {
        numSelectors = bound(numSelectors, 1, 10);
        selectorSeed = bound(selectorSeed, 1, type(uint256).max - numSelectors);

        address integration = _randomAddress();
        address admin = _randomAddress();
        assertNotEq(integration, admin, "integration and admin match");

        // set the integration admin
        integrationManagementHarness.setIntegrationAdmin(integration, admin);

        // set the integration registration status
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.REGISTERED
        );

        // create the selectors to update
        Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](
            numSelectors
        );
        for (uint256 i; i < numSelectors; i++) {
            uint256 j = uint256(_randomBytes32(selectorSeed));
            bytes4 selector = bytes4(bytes32(j));
            bool status = j % 2 == 0;

            updates[i] = Structs.FunctionProtectionStatusUpdate({fnSelector: selector, protectionEnabled: status});
        }

        vm.startPrank(admin);
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();

        // check the statuses
        for (uint256 i; i < updates.length; i++) {
            bool result = integrationManagementHarness.getIsIntegrationFunctionProtected(
                integration,
                updates[i].fnSelector
            );
            assertEq(result, updates[i].protectionEnabled, "status mismatch");
        }
    }

    // fails setting function protection to true when registration is revoked
    function test_RevertsWhen_EnablingFunctionProtectionWhenRegistrationRevoked_AsAdmin(uint256 selectorSeed) public {
        address integration = _randomAddress();
        address admin = _randomAddress();
        assertNotEq(integration, admin, "integration and admin match");

        // set the integration admin
        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        // set the integration registration status
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.REVOKED
        );

        Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](1);
        updates[0].fnSelector = bytes4(bytes32(keccak256(abi.encode(selectorSeed))));
        updates[0].protectionEnabled = true;
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_IntegrationRegistrationRevoked.selector);
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           registerIntegrationWithCube3
    //////////////////////////////////////////////////////////////*/

    // fails if called by non integration admin
    function testFuzz_RevertsWhen_RegisteringIntegration_AsNonIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        vm.startPrank(_randomAddress());
        vm.expectRevert(bytes(abi.encodeWithSelector(ProtocolErrors.Cube3Router_CallerNotIntegrationAdmin.selector)));
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if the protocol is paused
    function test_RevertsWhen_RegisteringWhenProtocolIsPaused_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        // set the integration admin
        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        integrationManagementHarness.updateProtocolConfig(_randomAddress(), true);
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_ProtocolPaused.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if integration is zero address
    function testFuzz_RevertsWhen_IntegrationProvidedIsZeroAddress_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            ,
            // unused integration
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(address(0), admin);
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Protocol_InvalidIntegration.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            address(0),
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if integration provided is an EOA
    function testFuzz_RevertsWhen_IntegrationIsEOA_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            ,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        address integration = _randomAddress();
        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Protocol_TargetNotAContract.selector, integration));
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if the integration is not pre-registered
    function testFuzz_RevertsWhen_IntegrationNotPreRegistered_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_IntegrationRegistrationStatusNotPending.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if the signature hash has already been used
    function testFuzz_RevertsWhen_SignatureHashReused_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );

        integrationManagementHarness.setUsedRegistrationSignatureHash(keccak256(registrarSignature));
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_RegistrarSignatureAlreadyUsed.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if the registry doesn't exist
    function testFuzz_RevertsWhen_NonExistentRegistry_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");

        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_RegistryNotSet.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if there's no registrar set
    function testFuzz_RevertsWhen_NoRegistrarSet_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );
        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), false);
        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_IntegrationSigningAuthorityNotSet.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails if the signature is invalid
    function testFuzz_RevertsWhen_RegistrarSignatureInvalid_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            address signer, // unused registrar isgnature
            ,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );
        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), false);
        mockRegistry.setSignatureAuthorityForIntegration(integration, signer);

        vm.startPrank(admin);
        vm.expectRevert(ECDSA.ECDSAInvalidSignature.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            new bytes(65),
            enabledByDefaultFnSelectors
        );
    }

    // succeeds registering integration with valid signature and no default selectors
    function testFuzz_SucceedsWhen_RegisteringIntegrationWithValidRegistrarAndNoDefaultSelectors_AsIntegrationAdmin(
        uint256 pvtKeySeed
    ) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            address signer,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 0);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );
        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), false);
        mockRegistry.setSignatureAuthorityForIntegration(integration, signer);

        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit IntegrationRegistrationStatusUpdated(integration, Structs.RegistrationStatusEnum.REGISTERED);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails registering integration with valid signature and default empty selectors
    function testFuzz_RevertsWhen_RegisteringIntegrationWithValidRegistrarAndNullSelectors_AsIntegrationAdmin(
        uint256 pvtKeySeed,
        uint256 numSelectors
    ) public {
        numSelectors = bound(numSelectors, 1, 24);
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            address signer,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, numSelectors);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );
        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), false);
        mockRegistry.setSignatureAuthorityForIntegration(integration, signer);

        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_InvalidFunctionSelector.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // Succeeds when registering the integration and setting the default selectors
    function testFuzz_SucceedsWhen_RegisteringIntegrationWithValidRegistrarAndDefaultSelectors_AsIntegrationAdmin(
        uint256 pvtKeySeed,
        uint256 numSelectors
    ) public {
        numSelectors = bound(numSelectors, 1, 24);
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            address signer,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, numSelectors);

        for (uint256 i; i < numSelectors; i++) {
            enabledByDefaultFnSelectors[i] = bytes4(bytes32(keccak256(abi.encode(pvtKeySeed, i))));
        }

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );
        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), false);
        mockRegistry.setSignatureAuthorityForIntegration(integration, signer);

        vm.startPrank(admin);
        for (uint256 i; i < numSelectors; i++) {
            vm.expectEmit(true, true, true, true);
            emit FunctionProtectionStatusUpdated(integration, enabledByDefaultFnSelectors[i], true);
        }
        vm.expectEmit(true, true, true, true);
        emit IntegrationRegistrationStatusUpdated(integration, Structs.RegistrationStatusEnum.REGISTERED);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    // fails registering an integration when the protocol is paused
    function test_RevertsWhen_RegisteringIntegration_WhenPaused_AsAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            address signer,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 0);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration,
            Structs.RegistrationStatusEnum.PENDING
        );

        // paused the protocol
        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), true);

        vm.startPrank(admin);
        vm.expectRevert(ProtocolErrors.Cube3Router_ProtocolPaused.selector);
        integrationManagementHarness.registerIntegrationWithCube3(
            integration,
            registrarSignature,
            enabledByDefaultFnSelectors
        );
    }

    /*//////////////////////////////////////////////////////////////
          batchUpdateIntegrationRegistrationStatus
    //////////////////////////////////////////////////////////////*/

    // fails if array lengths don't match
    function test_RevertsWhen_BatchUpdateArrayLengthsMismatch_AsAdmin(
        uint256 integrationsLength,
        uint256 statusesLength
    ) public {
        uint256 statusSeed = statusesLength;
        integrationsLength = bound(integrationsLength, 1, 16);
        statusesLength = bound(statusesLength, 1, 16);
        vm.assume(integrationsLength != statusesLength);

        address[] memory integrations = new address[](integrationsLength);
        for (uint256 i; i < integrationsLength; i++) {
            integrations[i] = _randomAddress();
        }

        Structs.RegistrationStatusEnum[] memory statuses = new Structs.RegistrationStatusEnum[](statusesLength);
        for (uint256 i; i < statusesLength; i++) {
            uint8 enumUint = uint8(uint256(keccak256(abi.encode(statusSeed, i))) % 4);
            statuses[i] = Structs.RegistrationStatusEnum(enumUint);
        }

        // assign the necessary role
        integrationManagementHarness.grantRole(CUBE3_INTEGRATION_MANAGER_ROLE, cube3Accounts.integrationManager);

        vm.startPrank(cube3Accounts.integrationManager);
        vm.expectRevert(ProtocolErrors.Cube3Protocol_ArrayLengthMismatch.selector);
        integrationManagementHarness.batchUpdateIntegrationRegistrationStatus(integrations, statuses);
        vm.stopPrank();
    }

    // fails if updating the status as a non admin
    function test_RevertsWhen_BatchUpdateingRegistrationStatus_AsNonAdmin(uint256 integrationsLength) public {
        uint256 statusSeed = integrationsLength;
        integrationsLength = bound(integrationsLength, 1, 16);

        address[] memory integrations = new address[](integrationsLength);
        for (uint256 i; i < integrationsLength; i++) {
            integrations[i] = _randomAddress();
        }

        Structs.RegistrationStatusEnum[] memory statuses = new Structs.RegistrationStatusEnum[](integrationsLength);
        for (uint256 i; i < integrationsLength; i++) {
            uint8 enumUint = uint8(uint256(keccak256(abi.encode(statusSeed, i))) % 4);
            statuses[i] = Structs.RegistrationStatusEnum(enumUint);
        }

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

    // succeeds updating multiple integration statuses and emitting the correct events
    function testFuzz_SucceedsWhen_BatchUpdatingRegistrations_AsAdmin(uint256 numRegistrations) public {
        uint256 statusSeed = numRegistrations;
        numRegistrations = bound(numRegistrations, 1, 16);

        address[] memory integrations = new address[](numRegistrations);
        for (uint256 i; i < numRegistrations; i++) {
            integrations[i] = _randomAddress();
        }

        Structs.RegistrationStatusEnum[] memory statuses = new Structs.RegistrationStatusEnum[](numRegistrations);
        for (uint256 i; i < numRegistrations; i++) {
            // we don't want to assign the status as UNREGISTERED so as to avoid the same status error
            // because all are UNREGISTERED by default
            uint8 enumUint = uint8(1 + (uint256(keccak256(abi.encode(statusSeed, i))) % 3));
            statuses[i] = Structs.RegistrationStatusEnum(enumUint);
        }

        // assign the necessary role
        integrationManagementHarness.grantRole(CUBE3_INTEGRATION_MANAGER_ROLE, cube3Accounts.integrationManager);

        vm.startPrank(cube3Accounts.integrationManager);
        for (uint256 i; i < numRegistrations; i++) {
            vm.expectEmit(true, true, true, true);
            emit IntegrationRegistrationStatusUpdated(integrations[i], statuses[i]);
        }
        integrationManagementHarness.batchUpdateIntegrationRegistrationStatus(integrations, statuses);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           fetchRegistryAndSigningAuthorityForIntegration
    //////////////////////////////////////////////////////////////*/

    function testFuzz_SucceedsWhen_FetchingSigningAuthorityForIntegration(uint256 numIntegrations) public {
        numIntegrations = bound(numIntegrations, 1, 16);

        address[] memory integrations = new address[](numIntegrations);
        address[] memory signers = new address[](numIntegrations);

        integrationManagementHarness.updateProtocolConfig(address(mockRegistry), false);

        for (uint256 i; i < numIntegrations; i++) {
            integrations[i] = _randomAddress();
            signers[i] = _randomAddress();
            mockRegistry.setSignatureAuthorityForIntegration(integrations[i], signers[i]);
        }

        for (uint256 i; i < numIntegrations; i++) {
            (address registry, address result) = integrationManagementHarness
                .fetchRegistryAndSigningAuthorityForIntegration(integrations[i]);
            assertEq(registry, address(mockRegistry));
            assertEq(result, signers[i], "signer mismatch");
        }
    }

    /*//////////////////////////////////////////////////////////////
           _updateIntegrationRegistrationStatus
    //////////////////////////////////////////////////////////////*/

    // fails if attempting to set the same status
    function testFuzz_RevertsWhen_UpdatingToTheSameRegistrationStatus(uint256 numRegistrations) public {
        uint256 registrationSeed = numRegistrations;
        numRegistrations = bound(numRegistrations, 1, 16);

        address[] memory integrations = new address[](numRegistrations);
        Structs.RegistrationStatusEnum[] memory statuses = new Structs.RegistrationStatusEnum[](numRegistrations);

        for (uint256 i; i < numRegistrations; i++) {
            integrations[i] = _randomAddress();
            uint8 enumUint = uint8(1 + (uint256(keccak256(abi.encode(registrationSeed, i))) % 3));
            statuses[i] = Structs.RegistrationStatusEnum(enumUint);
            integrationManagementHarness.wrappedUpdateIntegrationRegistrationStatus(integrations[i], statuses[i]);
        }

        for (uint256 i; i < numRegistrations; i++) {
            vm.expectRevert(ProtocolErrors.Cube3Router_CannotSetStatusToCurrentStatus.selector);
            integrationManagementHarness.wrappedUpdateIntegrationRegistrationStatus(integrations[i], statuses[i]);
            vm.stopPrank();
        }
    }

    // succeeds updating the registration status
    function testFuzz_SucceedsWhen_UpdatingRegistrationStatusForIntegration(uint256 statusSeed) public {
        uint8 enumUint = uint8(1 + (uint256(keccak256(abi.encode(statusSeed))) % 3));
        vm.expectEmit(true, true, true, true);
        address integration = _randomAddress();
        Structs.RegistrationStatusEnum status = Structs.RegistrationStatusEnum(enumUint);
        emit IntegrationRegistrationStatusUpdated(integration, status);
        integrationManagementHarness.wrappedUpdateIntegrationRegistrationStatus(integration, status);
        assertEq(
            uint256(status),
            uint256(integrationManagementHarness.getIntegrationStatus(integration)),
            "status mismatch"
        );
    }

    /*//////////////////////////////////////////////////////////////
           HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _generateMockRegistrationData(
        uint256 pvtKey,
        uint256 numSelectors
    )
        internal
        returns (
            address integration,
            address admin,
            address signer,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        )
    {
        integration = address(new MockTarget());
        admin = _randomAddress();
        signer = vm.addr(pvtKey);
        registrarSignature = PayloadCreationUtils.signPayloadData(
            abi.encodePacked(integration, admin, block.chainid),
            pvtKey
        );
        enabledByDefaultFnSelectors = new bytes4[](numSelectors);
    }
}
