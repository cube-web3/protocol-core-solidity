// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { BaseTest } from "../../BaseTest.t.sol";
import { Structs } from "../../../../src/common/Structs.sol";

import { IntegrationManagement } from "../../../../src/abstracts/IntegrationManagement.sol";

import {MockTarget} from "../../../mocks/MockContract.t.sol";
import {MockRegistry} from "../../../mocks/MockRegistry.t.sol";
import { IntegrationManagementHarness } from "../../harnesses/IntegrationManagementHarness.sol";

contract IntegrationManagement_Fuzz_Unit_Test is BaseTest {
    IntegrationManagementHarness integrationManagementHarness;
    MockRegistry mockRegistry;
    function setUp() public {
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
    )
        public
    {
        numSelectors = bound(numSelectors, 1, 10);
        selectorSeed = bound(selectorSeed, 1, type(uint256).max - numSelectors);

        address integration = _randomAddress();
        address admin = _randomAddress();
        assertNotEq(integration, admin, "integration and admin match");

        // set the integration admin
        integrationManagementHarness.setIntegrationAdmin(integration, admin);

        // set the integration registration status
        integrationManagementHarness.setIntegrationRegistrationStatus(
            integration, Structs.RegistrationStatusEnum.REGISTERED
        );

        // create the selectors to update
        Structs.FunctionProtectionStatusUpdate[] memory updates =
            new Structs.FunctionProtectionStatusUpdate[](numSelectors);
        for (uint256 i; i < numSelectors; i++) {
            uint256 j = uint256(_randomBytes32(selectorSeed));
            bytes4 selector = bytes4(bytes32(j));
            bool status = j % 2 == 0;

            updates[i] = Structs.FunctionProtectionStatusUpdate({ fnSelector: selector, protectionEnabled: status });
        }

        vm.startPrank(admin);
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();

        // check the statuses
        for (uint256 i; i < updates.length; i++) {
            bool result =
                integrationManagementHarness.getIsIntegrationFunctionProtected(integration, updates[i].fnSelector);
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
            integration, Structs.RegistrationStatusEnum.REVOKED
        );

        Structs.FunctionProtectionStatusUpdate[] memory updates = new Structs.FunctionProtectionStatusUpdate[](1);
        updates[0].fnSelector = bytes4(bytes32(keccak256(abi.encode(selectorSeed))));
        updates[0].protectionEnabled = true;
        vm.startPrank(admin);
        vm.expectRevert(bytes("TODO: RegistrationRevoked"));
        integrationManagementHarness.updateFunctionProtectionStatus(integration, updates);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
           registerIntegrationWithCube3
    //////////////////////////////////////////////////////////////*/

    // fails if called my non integration admin
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
        vm.expectRevert(bytes("TODO: Not admin"));
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, registrarSignature, enabledByDefaultFnSelectors
        );
    }

    // fails if integration is zero address
    function testFuzz_RevertsWhen_IntegrationProvidedIsZeroAddress_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            ,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(address(0), admin);
        vm.startPrank(admin);
        vm.expectRevert(bytes("TODO zero address"));
        integrationManagementHarness.registerIntegrationWithCube3(
            address(0), registrarSignature, enabledByDefaultFnSelectors
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
        vm.expectRevert(bytes("TODO: Not a contract"));
        integrationManagementHarness.registerIntegrationWithCube3(
           integration , registrarSignature, enabledByDefaultFnSelectors
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
        vm.expectRevert(bytes("GK13: not PENDING"));
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, registrarSignature, enabledByDefaultFnSelectors
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

        integrationManagementHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.PENDING);
        
        integrationManagementHarness.setUsedRegistrationSignatureHash(
            keccak256(registrarSignature)
        );
        vm.startPrank(admin);
        vm.expectRevert("CR13: registrar reuse");
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, registrarSignature, enabledByDefaultFnSelectors
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

        integrationManagementHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.PENDING);
        vm.startPrank(admin);
        vm.expectRevert("TODO: No Registry");
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, registrarSignature, enabledByDefaultFnSelectors
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
        integrationManagementHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.PENDING);
        integrationManagementHarness.setProtocolConfig(address(mockRegistry), false);
        vm.startPrank(admin);
        vm.expectRevert("TODO: No Registrar");
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, registrarSignature, enabledByDefaultFnSelectors
        );
    }

    // fails if the signature is invalid
     function testFuzz_RevertsWhen_RegistrarSignatureInvalid_AsIntegrationAdmin(uint256 pvtKeySeed) public {
        pvtKeySeed = bound(pvtKeySeed, 1, type(uint128).max);
        (
            address integration,
            address admin,
            address signer,
            bytes memory registrarSignature,
            bytes4[] memory enabledByDefaultFnSelectors
        ) = _generateMockRegistrationData(pvtKeySeed, 1);

        integrationManagementHarness.setIntegrationAdmin(integration, admin);
        assertEq(admin, integrationManagementHarness.getIntegrationAdmin(integration), "admin not set");
        integrationManagementHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.PENDING);
        integrationManagementHarness.setProtocolConfig(address(mockRegistry), false);
        mockRegistry.setSignatureAuthorityForIntegration(integration, signer);

        vm.startPrank(admin);
        vm.expectRevert("TODO: InvalidSignature");     
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, new bytes(65), enabledByDefaultFnSelectors
        );
    }

    // succeeds registering integration with valid signature and no default selectors
    function testFuzz_SucceedsWhen_RegisteringIntegrationWithValidRegistrarAndNoDefaultSelectors_AsIntegrationAdmin(uint256 pvtKeySeed) public {
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
        integrationManagementHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.PENDING);
        integrationManagementHarness.setProtocolConfig(address(mockRegistry), false);
        mockRegistry.setSignatureAuthorityForIntegration(integration, signer);

        vm.startPrank(admin);
        vm.expectEmit(true,true,true,true);  
         emit IntegrationRegistrationStatusUpdated(integration, Structs.RegistrationStatusEnum.REGISTERED);  
        integrationManagementHarness.registerIntegrationWithCube3(
            integration, registrarSignature, enabledByDefaultFnSelectors
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
        registrarSignature = _createSignature(abi.encodePacked(integration, admin, block.chainid), pvtKey);
        enabledByDefaultFnSelectors = new bytes4[](numSelectors);
    }
}
