// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Script.sol";

import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Cube3RouterImpl} from "@src/Cube3RouterImpl.sol";

import {Cube3Registry} from "@src/Cube3Registry.sol";

import {ProtocolAdminRoles} from "@src/common/ProtocolAdminRoles.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";

abstract contract DeployUtils is Script, ProtocolAdminRoles {
    // access control roles
    bytes32 internal constant DEFAULT_ADMIN_ROLE = bytes32(0);

    uint256 internal constant EXPECTED_SIGNATURE_MODULE_PAYLOAD_LENGTH = 320;

    // used for writing the json files
    struct AddressMapping {
        string key;
        address value;
    }

    // Router
    address internal routerImplAddr;
    address internal routerProxyAddr;
    ERC1967Proxy internal cubeRouterProxy;
    Cube3RouterImpl internal wrappedRouterProxy;

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
        string memory _signatureModuleVersion
    ) internal {
        address deployer = vm.addr(_deployerPvtKey);

        // ============ registry
        registry = new Cube3Registry(_protocolAdmin);
        // _addAccessControlAndRevokeDeployerPermsForRegistry(_protocolAdmin, _keyManager, vm.addr(_deployerPvtKey));

        // ============ router
        // deploy the implementation
        routerImplAddr = address(new Cube3RouterImpl());
        // deploy the proxy
        cubeRouterProxy = new ERC1967Proxy(
            routerImplAddr,
            abi.encodeCall(Cube3RouterImpl.initialize, (address(registry), _protocolAdmin))
        );

        // renounce the role as the deployer, new roles will be assigned by the protocol admin
        // wrappedRouterProxy.renounceRole(DEFAULT_ADMIN_ROLE, deployer);

        // renounce the deployer role, which will be reassigned by the protocol admin
        // registry.renounceRole(DEFAULT_ADMIN_ROLE, deployer);
        require(!registry.hasRole(DEFAULT_ADMIN_ROLE, deployer), "router: no cube3 admin role");

        // create a wrapper interface (for convenience)
        wrappedRouterProxy = Cube3RouterImpl(payable(address(cubeRouterProxy)));
        require(!wrappedRouterProxy.hasRole(DEFAULT_ADMIN_ROLE, deployer), "router: deployer still default admin");
        // _addAccessControlAndRevokeDeployerPermsForRouter(_protocolAdmin, _integrationAdmin, vm.addr(_deployerPvtKey));

        // =========== signature module
        signatureModule = new Cube3SignatureModule(address(cubeRouterProxy), _signatureModuleVersion, _backupSigner);
    }
    // trick foundry into ignoring for coverage

    function _addAccessControlAndRevokeDeployerPermsForRouter(
        address protocolAdmin,
        address integrationManager,
        address deployer
    ) internal {
        // make the multisig the default admin
        // wrappedRouterProxy.grantRole(DEFAULT_ADMIN_ROLE, protocolAdmin);
        // require(wrappedRouterProxy.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin), "router: no default admin role");

        // make the multisig the protocol admin
        wrappedRouterProxy.grantRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin);
        require(wrappedRouterProxy.hasRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin), "router: no cube3 admin role");

        wrappedRouterProxy.grantRole(CUBE3_INTEGRATION_MANAGER_ROLE, integrationManager);
        require(
            wrappedRouterProxy.hasRole(CUBE3_INTEGRATION_MANAGER_ROLE, integrationManager),
            "router: no cube3 integration  role"
        );

        // wrappedRouterProxy.renounceRole(DEFAULT_ADMIN_ROLE, deployer);
        // require(!wrappedRouterProxy.hasRole(DEFAULT_ADMIN_ROLE, deployer), "router: deployer still default admin");
    }

    function _addAccessControlAndRevokeDeployerPermsForRegistry(
        address protocolAdmin,
        address keyManager,
        address deployer
    ) internal {
        // registry.grantRole(DEFAULT_ADMIN_ROLE, protocolAdmin);
        // require(registry.hasRole(DEFAULT_ADMIN_ROLE, protocolAdmin), "router: no default admin role");

        registry.grantRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin);
        require(registry.hasRole(CUBE3_PROTOCOL_ADMIN_ROLE, protocolAdmin), "router: no cube3 admin role");

        registry.grantRole(CUBE3_KEY_MANAGER_ROLE, keyManager);
        require(registry.hasRole(CUBE3_KEY_MANAGER_ROLE, keyManager), "router: keyManager role");

        // registry.renounceRole(DEFAULT_ADMIN_ROLE, deployer);
        // require(!registry.hasRole(DEFAULT_ADMIN_ROLE, deployer), "router: no cube3 admin role");
    }
}
