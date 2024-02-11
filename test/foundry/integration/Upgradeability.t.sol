// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { IntegrationTest } from "../IntegrationTest.t.sol";

import {MockRouter} from "../../mocks/MockRouter.t.sol";
import {MockRegistry} from "../../mocks/MockRegistry.t.sol";

import {Cube3RouterImpl} from "../../../src/Cube3RouterImpl.sol";

import {ProtocolErrors} from "../../../src/libs/ProtocolErrors.sol";

import {DemoUpgradeableUUPS} from "../../demo/DemoUpgradeableUUPS.sol";

contract Integration_Upgradeability_Concrete_Test is IntegrationTest {

ERC1967Proxy public uupsIntegrationProxy;
DemoUpgradeableUUPS public demoUUPS;
DemoUpgradeableUUPS public wrappedDemoUUPS;
Cube3RouterImpl public cube3RouterImpl;
ERC1967Proxy public routerProxy;

MockRouter mockRouter;
MockRegistry mockRegistry;

address integrationAdmin;

 function setUp() public override {
     super.setUp();

     mockRegistry = new MockRegistry();

 }

 function _deployCube3ProxyAndImplementation() internal {
    cube3RouterImpl = new Cube3RouterImpl();
    routerProxy = new ERC1967Proxy(
        address(cube3RouterImpl), 
        abi.encodeCall(Cube3RouterImpl.initialize, (address(mockRegistry)))
    );
 }

 // fails when initializing the router implementation with a null registry address
 function test_RevertsWhen_InitializingRouterImplementationWithNullRegistry() public {
    cube3RouterImpl = new Cube3RouterImpl();
    vm.expectRevert(ProtocolErrors.Cube3Router_InvalidRegistry.selector);
    routerProxy = new ERC1967Proxy(
        address(cube3RouterImpl), 
        abi.encodeCall(Cube3RouterImpl.initialize, (address(0)))
    );
 }

 // fails when initializing the router implementation with an EOA as the registry

    function test_SucceedsWhen_DeployingProxyAndInitializingCube3Router() public {
        _deployCube3ProxyAndImplementation();
        assertTrue(address(cube3RouterImpl) != address(0));
        assertTrue(address(routerProxy) != address(0));
        // assertTrue(cube3RouterImpl.registry() == address(mockRegistry));
    }
/*
 function _deployProxyAndImplementation() internal returns (DemoUpgradeableUUPS, ERC1967Proxy) {

    integrationAdmin = _randomAddress();

    vm.startPrank(integrationAdmin);
    demoUUPS = new DemoUpgradeableUUPS();
    // deploy integration proxy
    uupsIntegrationProxy = new ERC1967Proxy(
        address(demoUUPS),
        abi.encodeCall(DemoUpgradeableUUPS.initialize, (address(mockRouter), integrationAdmin, true))
    );

    // wrap the proxy with the impl's ABI for convenience
    wrappedDemoUUPS = DemoUpgradeableUUPS(payable(uupsIntegrationProxy));
    vm.stopPrank();

 }
 */

 function test_SucceedsWhen_DeployingAndInitializingUUPSProxyIntegration() public {
    //  _deployProxyAndImplementation();
    //  assertTrue(address(demoUUPS) != address(0));
    //  assertTrue(address(uupsIntegrationProxy) != address(0));
    //  assertTrue(demoUUPS.owner() == integrationAdmin);
    //  assertTrue(demoUUPS.router() == address(mockRouter));
 }

 
}