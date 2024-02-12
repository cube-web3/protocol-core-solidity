// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { ICube3RouterImpl } from "@src/interfaces/ICube3RouterImpl.sol";
import { BaseTest } from "@test/foundry/BaseTest.t.sol";

import { RouterHarness } from "@test/foundry/harnesses/RouterHarness.sol";
import { PayloadCreationUtils } from "@test/libs/PayloadCreationUtils.sol";
import { ProtocolErrors } from "@src/libs/ProtocolErrors.sol";
import { Structs } from "@src/common/Structs.sol";

contract Router_Concrete_Unit_Test is BaseTest {
    RouterHarness routerHarness;

    function setUp() public override {
        routerHarness = new RouterHarness();
    }

    // fails when calling initialze externally outside of the constructor
    function test_RevertsWhen_InitializingOutsideTheConstructor() public {
        address mockRegistry = _randomAddress();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        routerHarness.initialize(mockRegistry);
    }

    // fails when initializing with a zero address registry.

    // fails when registry is an EOA

    /*//////////////////////////////////////////////////////////////
            routeToModule
    //////////////////////////////////////////////////////////////*/

    // Succeeds if routing is bypassed
    function test_SucceedsWhen_RoutingToModule_WhenProtectionBypassed() public {
        (address integration,, bytes4 selector) = _getRandomRoutingInfo();

        // without fn protection enabled for `selector`, the router will bypass routing and return early
        vm.startPrank(integration);
        bytes32 returned =
            routerHarness.routeToModule(_randomAddress(), 0, abi.encodePacked(selector, _getRandomBytes(256)));

        assertEq(returned, PROCEED_WITH_CALL, "incorrect return value");
    }

    // Fails if module doesn't exist
    function test_RevertsWhen_ModuleIdDoesNotExist() public {
        (address integration,, bytes4 selector) = _getRandomRoutingInfo();

        // enable fn protection
        routerHarness.setFunctionProtectionStatus(integration, selector, true);
        assertTrue(routerHarness.getIsIntegrationFunctionProtected(integration, selector), "not protected");

        // set as REGISTERED
        routerHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REGISTERED);
        assertEq(
            uint256(routerHarness.getIntegrationStatus(integration)),
            uint256(Structs.RegistrationStatusEnum.REGISTERED),
            "not registered"
        );

        // is not paused
        assertFalse(routerHarness.getIsProtocolPaused(), "paused");

        // create a mock moduleId
        bytes16 moduleId = bytes16(uint128(uint160(address(_randomAddress()))));
        uint256 mockPayloadLength = 130;

        // create the mock calldata, with a legitimate routing bitmap as the last word
        uint256 routingBitmap =
            PayloadCreationUtils.createRoutingFooterBitmap(moduleId, selector, uint32(mockPayloadLength), 0);
        bytes memory mockCalldataWithRoutingBitmap =
            abi.encodePacked(selector, _getRandomBytes(256), _getRandomBytes(mockPayloadLength), routingBitmap);

        vm.startPrank(integration);
        vm.expectRevert(abi.encodeWithSelector(ProtocolErrors.Cube3Router_ModuleNotInstalled.selector, moduleId));
        routerHarness.routeToModule(_randomAddress(), 0, mockCalldataWithRoutingBitmap);
    }

    /*//////////////////////////////////////////////////////////////
            _shouldBypassRouting
    //////////////////////////////////////////////////////////////*/

    // succeeds (returns true) when the integration's registration status is pending
    // note: An integration with a registration status of PENDING cannot enable protection for a function's
    // selector until it is registered, so the first check will force the return.
    function test_SucceedsWhen_BypassingRouting_WhenIntegrationStatusIsPending() public {
        (address integration,, bytes4 selector) = _getRandomRoutingInfo();

        // set the registration status to PENDING
        routerHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.PENDING);

        vm.startPrank(integration);
        assertTrue(routerHarness.shouldBypassRouting(selector));
    }

    // succeeds (returns true) when the protocol is paused
    // note: fn protection status needs to be enabled. status must be REGISTERED.
    function test_SucceedsWhen_BypassingRouting_WhenProtocolPaused() public {
        (address integration, address registry, bytes4 selector) = _getRandomRoutingInfo();

        // enable fn protection
        routerHarness.setFunctionProtectionStatus(integration, selector, true);
        assertTrue(routerHarness.getIsIntegrationFunctionProtected(integration, selector), "not protected");

        // set as REGISTERED
        routerHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REGISTERED);
        assertEq(
            uint256(routerHarness.getIntegrationStatus(integration)),
            uint256(Structs.RegistrationStatusEnum.REGISTERED),
            "not registered"
        );

        vm.expectEmit(true, true, true, true);
        emit ProtocolConfigUpdated(registry, true);
        routerHarness.wrappedSetProtocolConfig(registry, true);

        vm.startPrank(integration);
        assertTrue(routerHarness.shouldBypassRouting(selector));
    }

    // succees (returns true) when the function is protected, but registration status is revoked
    function test_SucceedsWhen_BypassRouting_WhenRegistrationStatusRevoked() public {
        (address integration,, bytes4 selector) = _getRandomRoutingInfo();
        // enable fn protection
        routerHarness.setFunctionProtectionStatus(integration, selector, true);
        assertTrue(routerHarness.getIsIntegrationFunctionProtected(integration, selector), "not protected");

        // set as REVOKED
        routerHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REVOKED);
        assertEq(
            uint256(routerHarness.getIntegrationStatus(integration)),
            uint256(Structs.RegistrationStatusEnum.REVOKED),
            "not registered"
        );

        vm.startPrank(integration);

        // should bypass routing because it's revoked
        assertTrue(routerHarness.shouldBypassRouting(selector), "bypassed");
    }

    //  event log_named_bytes4(string name, bytes4 sel);

    // succeeds (returns false) when the function is protected, integration is REGISTERED,
    // and protocol is not paused
    function test_SucceedsWhen_Routing_WhenProtectedAndRegisteredAndNotPaused() public {
        (address integration,, bytes4 selector) = _getRandomRoutingInfo();

        emit log_named_bytes4("selector", selector);

        // enable fn protection
        routerHarness.setFunctionProtectionStatus(integration, selector, true);
        assertTrue(routerHarness.getIsIntegrationFunctionProtected(integration, selector), "not protected");

        // set as REGISTERED
        routerHarness.setIntegrationRegistrationStatus(integration, Structs.RegistrationStatusEnum.REGISTERED);
        assertEq(
            uint256(routerHarness.getIntegrationStatus(integration)),
            uint256(Structs.RegistrationStatusEnum.REGISTERED),
            "not registered"
        );

        // is not paused
        assertFalse(routerHarness.getIsProtocolPaused(), "paused");

        vm.startPrank(integration);
        // should not bypass routing
        assertFalse(routerHarness.shouldBypassRouting(selector), "bypassed");
    }

    function _getRandomRoutingInfo() internal view returns (address integration, address registry, bytes4 selector) {
        integration = _randomAddress();
        registry = _randomAddress();
        selector = bytes4(bytes32(uint256(keccak256(abi.encode(_randomAddress())))));
    }

    // Succeeds when checking the supported interface
    function test_SucceedsWhen_CheckingICube3RouterInterfaceSupport() public {
        assertTrue(routerHarness.supportsInterface(type(ICube3RouterImpl).interfaceId), "interface not supported");
    }
}
