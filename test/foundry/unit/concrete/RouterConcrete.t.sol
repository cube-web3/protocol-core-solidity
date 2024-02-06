// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import { BaseTest } from "../../BaseTest.t.sol";

import { RouterHarness } from "../../harnesses/RouterHarness.sol";

import { ICube3Router } from "../../../../src/interfaces/ICube3Router.sol";

import { Structs } from "../../../../src/common/Structs.sol";

contract Router_Concrete_Unit_Test is BaseTest {
    RouterHarness routerHarness;

    function setUp() public {
        routerHarness = new RouterHarness();
    }

    // fails when calling initialze externally outside of the constructor
    function test_RevertsWhen_InitializingOutsideTheConstructor() public {
        address mockRegistry = _randomAddress();
        routerHarness.initialize(mockRegistry);
    }

    // fails when initializing with a zero address registry.

    // fails when registry is an EOA

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

    //  event log_named_bytes4(string name, bytes4 sel);

    // succeeds (returns false) when the function is protected, integration is REGISTERED,
    // and protocol is not paused
    function test_SucceedsWhen_Routing_WhenProtectedAndRegisteredAndNotPaused() public {
        (address integration, address registry, bytes4 selector) = _getRandomRoutingInfo();

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

    function _getRandomRoutingInfo() internal returns (address integration, address registry, bytes4 selector) {
        integration = _randomAddress();
        registry = _randomAddress();
        selector = bytes4(bytes32(uint256(keccak256(abi.encode(_randomAddress())))));
    }
}
