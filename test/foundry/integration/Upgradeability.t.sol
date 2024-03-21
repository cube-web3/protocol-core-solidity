// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Cube3RouterImpl} from "@src/Cube3RouterImpl.sol";
import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";
import {ProtocolAdminRoles} from "@src/common/ProtocolAdminRoles.sol";
import {IntegrationTest} from "@test/foundry/IntegrationTest.t.sol";
import {MockRouter} from "@test/mocks/MockRouter.t.sol";
import {MockRegistry} from "@test/mocks/MockRegistry.t.sol";
import {DemoUpgradeableUUPS} from "@test/demo/DemoUpgradeableUUPS.sol";

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
        assertEq(address(cube3RouterImpl), _getProxyImpl(address(routerProxy)), "impl not matching");
    }

    // fails when intializing as an EOA
    function test_RevertsWhen_InitializingRouterImplementationAsEOA() public {
        cube3RouterImpl = new Cube3RouterImpl();
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        cube3RouterImpl.initialize(address(mockRegistry));
    }

    // succeeds upgrading the router implementation and storage remaining the same
    function test_SucceedsWhen_UpgradingProxyImplementation_AsProtocolAdmin() public {
        vm.startPrank(cube3Accounts.deployer, cube3Accounts.deployer);
        _deployCube3ProxyAndImplementation();

        Cube3RouterImpl(address(routerProxy)).grantRole(
            ProtocolAdminRoles.CUBE3_PROTOCOL_ADMIN_ROLE,
            cube3Accounts.protocolAdmin
        );
        vm.stopPrank();

        // pause the protocol
        vm.startPrank(cube3Accounts.protocolAdmin);
        Cube3RouterImpl(address(routerProxy)).setPausedUnpaused(true);
        assertTrue(Cube3RouterImpl(address(routerProxy)).getIsProtocolPaused(), "not paused");

        // deploy a new impl and upgrade
        Cube3RouterImpl newRouterImpl = new Cube3RouterImpl();
        Cube3RouterImpl(address(routerProxy)).upgradeToAndCall(address(newRouterImpl), new bytes(0));
        assertEq(
            address(newRouterImpl),
            Cube3RouterImpl(address(routerProxy)).getImplementation(),
            "impl not matching"
        );

        // check the protocol is still paused
        assertTrue(Cube3RouterImpl(address(routerProxy)).getIsProtocolPaused(), "not paused");
    }

    function _getProxyImpl(address proxy) internal view returns (address) {
        // Implementation storage slot specified by EIP1967.
        bytes32 IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        address impl = address(uint160(uint256(vm.load(address(proxy), IMPL_SLOT))));
        return impl;
    }
}
