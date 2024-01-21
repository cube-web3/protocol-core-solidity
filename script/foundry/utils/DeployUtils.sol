// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";

import {ERC1967Proxy} from "@openzeppelin/src/proxy/ERC1967/ERC1967Proxy.sol";
import {Cube3Router} from "../../../src/Cube3Router.sol";

import {Cube3Registry} from "../../../src/Cube3Registry.sol";
import {Cube3SignatureModule} from "../../../src/modules/Cube3SignatureModule.sol";
// import {LibDeployConstants} from "../utils/LibDeployConstants.sol";

abstract contract DeployUtils is Script {
    // access control roles
    bytes32 internal constant CUBE3_PROTOCOL_ADMIN_ROLE = keccak256("CUBE3_PROTOCOL_ADMIN_ROLE");
    bytes32 internal constant CUBE3_INTEGRATION_ADMIN_ROLE = keccak256("CUBE3_INTEGRATION_ADMIN_ROLE");
    bytes32 internal constant CUBE3_KEY_MANAGER_ROLE = keccak256("CUBE3_KEY_MANAGER_ROLE");
    bytes32 internal constant DEFAULT_ADMIN_ROLE = bytes32(0);

    event consoleLog(string log);
    event consoleLog(string key, address value);
    event consoleLog(string key, uint256 value);
    event consoleLog(string key, bytes value);
    event consoleLog(string key, bytes32 value);

    // used for writing the json files
    struct AddressMapping {
        string key;
        address value;
    }

    // Router
    address internal routerImplAddr;
    address internal routerProxyAddr;
    ERC1967Proxy internal cubeRouterProxy;
    Cube3Router internal wrappedRouterProxy;

    // Registr
    Cube3Registry internal registry;

    // Signature Module
    Cube3SignatureModule internal signatureModule;

    function _contractExistsAtAddress(address contractAddress) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(contractAddress)
        }
        return (size > 0);
    }

    function _convertBytesToAddress(bytes memory input) internal pure returns (address) {
        require(input.length == 20, "Input must be 20 bytes long.");
        address addr;
        assembly {
            addr := mload(add(input, 20))
        }
        return addr;
    }

    function _deployProtocol(
        uint256 _deployerPvtKey,
        address _protocolAdmin,
        address _keyManager,
        address _integrationAdmin,
        address _backupSigner,
        uint256 _signatureModulePayloadLength,
        string memory _signatureModuleVersion
    ) internal {
        vm.startBroadcast(_deployerPvtKey);

        // ============ registry
        registry = new Cube3Registry();
        _addAccessControlAndRevokeDeployerPermsForRegistry(_protocolAdmin, _keyManager, vm.addr(_deployerPvtKey));

        // ============ router
        // deploy the implementation
        routerImplAddr = address(new Cube3Router());
        // deploy the proxy
        cubeRouterProxy = new ERC1967Proxy(routerImplAddr, abi.encodeCall(Cube3Router.initialize, address(registry)));
        // create a wrapper interface (for convenience)
        wrappedRouterProxy = Cube3Router(payable(address(cubeRouterProxy)));
        _addAccessControlAndRevokeDeployerPermsForRouter(_protocolAdmin, _integrationAdmin, vm.addr(_deployerPvtKey));

        // =========== signature module
        signatureModule = new Cube3SignatureModule(address(cubeRouterProxy), _signatureModuleVersion, _backupSigner, _signatureModulePayloadLength);

        vm.stopBroadcast();
    }
    // trick foundry into ignoring for coverage

    function _addAccessControlAndRevokeDeployerPermsForRouter(
        address protocolAdmin,
        address integrationAdmin,
        address deployer
    ) internal {
        // make the multisig the default admin
        wrappedRouterProxy.grantRole(DEFAULT_ADMIN_ROLE, protocolAdmin);
        require(wrappedRouterProxy.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin), "router: no default admin role");

        // make the multisig the protocol admin
        wrappedRouterProxy.grantRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin);
        require(wrappedRouterProxy.hasRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin), "router: no cube3 admin role");

        wrappedRouterProxy.grantRole(CUBE3_INTEGRATION_ADMIN_ROLE, integrationAdmin);
        require(
            wrappedRouterProxy.hasRole(CUBE3_INTEGRATION_ADMIN_ROLE, integrationAdmin),
            "router: no cube3 integration  role"
        );

        wrappedRouterProxy.renounceRole(DEFAULT_ADMIN_ROLE, deployer);
        require(!wrappedRouterProxy.hasRole(DEFAULT_ADMIN_ROLE, deployer), "router: deployer still default admin");
    }

    function _addAccessControlAndRevokeDeployerPermsForRegistry(
        address protocolAdmin,
        address keyManager,
        address deployer
    ) internal {
        registry.grantRole(DEFAULT_ADMIN_ROLE, protocolAdmin);
        require(registry.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin), "router: no default admin role");

        registry.grantRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin);
        require(registry.hasRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin), "router: no cube3 admin role");

        registry.grantRole(CUBE3_KEY_MANAGER_ROLE, keyManager);
        require(registry.hasRole(CUBE3_KEY_MANAGER_ROLE, keyManager), "router: keyManager role");

        registry.renounceRole(DEFAULT_ADMIN_ROLE, deployer);
        require(!registry.hasRole(DEFAULT_ADMIN_ROLE, deployer), "router: no cube3 admin role");
    }
}
