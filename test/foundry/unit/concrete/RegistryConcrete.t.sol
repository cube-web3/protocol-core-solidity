// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { BaseTest } from "../../BaseTest.t.sol";
import { RegistryHarness } from "../../harnesses/RegistryHarness.sol";
import { ProtocolErrors } from "../../../../src/libs/ProtocolErrors.sol";
import { ICube3Registry } from "../../../../src/interfaces/ICube3Registry.sol";

contract Registry_Concrete_Unit_Test is BaseTest {
    RegistryHarness registryHarness;

    function setUp() public {
        _createCube3Accounts();
        registryHarness = new RegistryHarness();
    }

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    // succeeds when deployer is assigned the correct role
    function test_SucceedsWhen_AssigningDeployerCorrectRole() public {
        address deployer = _randomAddress();
        vm.startBroadcast(deployer);
        RegistryHarness registryConstructor = new RegistryHarness();
        vm.stopBroadcast();

        assertTrue(registryConstructor.hasRole(registryConstructor.DEFAULT_ADMIN_ROLE(), deployer), "no role");
    }

    // fails when a random address is not assigned the correct role
    function test_RevertsWhen_UserIsNotDeployer() public {
        address deployer = _randomAddress();
        vm.startBroadcast(deployer);
        RegistryHarness registryConstructor = new RegistryHarness();
        vm.stopBroadcast();

        assertFalse(
            registryConstructor.hasRole(registryConstructor.DEFAULT_ADMIN_ROLE(), _randomAddress()), "incorrect"
        );
    }

    /*//////////////////////////////////////////////////////////////
            setClientSigningAuthority
    //////////////////////////////////////////////////////////////*/

    // fails when caller does not have teh key manager role
    function test_RevertsWhen_SettingSigningAuthority_WithoutRole() public {
        address integrationContract = _randomAddress();
        address clientSigningAuthority = _randomAddress();

        address account = _randomAddress();
        vm.startBroadcast(account);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, account, CUBE3_KEY_MANAGER_ROLE
            )
        );
        registryHarness.setClientSigningAuthority(integrationContract, clientSigningAuthority);
    }

    // succeeds when caller has the key manager role
    function test_SucceedsWhen_SettingSigningAuthority_AsKeyManager() public {
        address integrationContract = _randomAddress();
        address clientSigningAuthority = _randomAddress();

        registryHarness.grantRole(CUBE3_KEY_MANAGER_ROLE, cube3Accounts.keyManager);

        vm.startBroadcast(cube3Accounts.keyManager);
        registryHarness.setClientSigningAuthority(integrationContract, clientSigningAuthority);
        vm.stopBroadcast();

        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrationContract),
            clientSigningAuthority,
            "incorrect authority"
        );
    }

    /*//////////////////////////////////////////////////////////////
            batchSetSigningAuthority
    //////////////////////////////////////////////////////////////*/

    // reverts when caller does not have the key manager role
    function testFuzz_RevertsWhen_BatchSettingSigningAuthority_WithoutRole() public {
        address[] memory integrations = new address[](1);
        address[] memory signingAuthorities = new address[](1);
        integrations[0] = _randomAddress();
        signingAuthorities[0] = _randomAddress();

        address account = _randomAddress();
        vm.startBroadcast(account);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, account, CUBE3_KEY_MANAGER_ROLE
            )
        );
        registryHarness.batchSetSigningAuthority(integrations, signingAuthorities);
    }

    // succeeds when caller is the key manager
    function testFuzz_SucceedsWhen_BatchSettingSigningAuthority_AsKeyManager() public {
        address[] memory integrations = new address[](1);
        address[] memory signingAuthorities = new address[](1);
        integrations[0] = _randomAddress();
        signingAuthorities[0] = _randomAddress();

        registryHarness.grantRole(CUBE3_KEY_MANAGER_ROLE, cube3Accounts.keyManager);

        vm.startBroadcast(cube3Accounts.keyManager);
        registryHarness.batchSetSigningAuthority(integrations, signingAuthorities);
        vm.stopBroadcast();

        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrations[0]),
            signingAuthorities[0],
            "incorrect authority"
        );
    }

    /*//////////////////////////////////////////////////////////////
            batchSetSigningAuthority
    //////////////////////////////////////////////////////////////*/

    // reverts when caller does not have the key manager role
    function test_RevertsWhen_RevokingSigningAuthority_WithoutRole() public {
        address integrationContract = _randomAddress();
        address clientSigningAuthority = _randomAddress();

        address account = _randomAddress();
        vm.startBroadcast(account);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, account, CUBE3_KEY_MANAGER_ROLE
            )
        );
        registryHarness.revokeSigningAuthorityForIntegration(integrationContract);
    }

    // succees when caller is the key manager
    function test_SucceedsWhen_RevokingSigningAuthority_AsKeyManager() public {
        address integrationContract = _randomAddress();
        address clientSigningAuthority = _randomAddress();

        registryHarness.grantRole(CUBE3_KEY_MANAGER_ROLE, cube3Accounts.keyManager);
        vm.startBroadcast(cube3Accounts.keyManager);

        registryHarness.setClientSigningAuthority(integrationContract, clientSigningAuthority);
        registryHarness.revokeSigningAuthorityForIntegration(integrationContract);
        vm.stopBroadcast();

        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrationContract), address(0), "incorrect authority"
        );
    }

    /*//////////////////////////////////////////////////////////////
            batchRevokeSigningAuthoritiesForIntegrations
    //////////////////////////////////////////////////////////////*/

    // reverts when caller does not have the key manager role
    function test_RevertsWhen_BatchRevokingSigningAuthorities_WithoutRole() public {
        address[] memory integrations = new address[](1);
        integrations[0] = _randomAddress();

        address account = _randomAddress();
        vm.startBroadcast(account);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, account, CUBE3_KEY_MANAGER_ROLE
            )
        );
        registryHarness.batchRevokeSigningAuthoritiesForIntegrations(integrations);
    }

    // succeeds when caller is the key manager
    function test_SucceedsWhen_BatchRevokingSigningAuthorities_AsKeyManager() public {
        address[] memory integrations = new address[](1);
        integrations[0] = _randomAddress();

        registryHarness.grantRole(CUBE3_KEY_MANAGER_ROLE, cube3Accounts.keyManager);
        vm.startBroadcast(cube3Accounts.keyManager);

        registryHarness.setClientSigningAuthority(integrations[0], _randomAddress());
        registryHarness.batchRevokeSigningAuthoritiesForIntegrations(integrations);
        vm.stopBroadcast();

        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrations[0]), address(0), "incorrect authority"
        );
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/

    // succeeds when contract supports IERC165
    function test_SucceedsWhen_SupportingIERC165() public {
        assertTrue(registryHarness.supportsInterface(type(IERC165).interfaceId), "does not support");
    }

    // succeeds when the contract supports ICube3Registry
    function test_SucceedsWhen_SupportingICube3Registry() public {
        assertTrue(registryHarness.supportsInterface(type(ICube3Registry).interfaceId), "does not support");
    }

    // succeeds when the contract does not support an unknown interface
    function test_SucceedsWhen_NotSupportingUnknownInterface() public {
        bytes4 unknownInterface = bytes4(bytes32(uint256(uint160(address(_randomAddress())))));
        assertFalse(registryHarness.supportsInterface(unknownInterface));
    }

    /*//////////////////////////////////////////////////////////////
            _setClientSigningAuthority
    //////////////////////////////////////////////////////////////*/

    // fails when the integration is the zero address
    function test_RevertsWhen_IntegrationToZeroAddress() public {
        address clientSigningAuthority = _randomAddress();
        vm.expectRevert(ProtocolErrors.Cube3Protocol_InvalidIntegration.selector);
        registryHarness.wrappedSetSigningAuthority(address(0), clientSigningAuthority);
    }

    // fails when the authority is the zero address
    function test_RevertsWhen_SettingClientAuthorityToZeroAddress() public {
        address integrationContract = _randomAddress();
        vm.expectRevert(ProtocolErrors.Cube3Registry_InvalidSigningAuthority.selector);
        registryHarness.wrappedSetSigningAuthority(integrationContract, address(0));
    }

    // succeeds when the integration and authority are not the zero address and emits the correct event
    function test_SucceedsWhen_SettingClientAuthority() public {
        address integrationContract = _randomAddress();
        address clientSigningAuthority = _randomAddress();

        vm.expectEmit(true, true, true, true);
        emit SigningAuthorityUpdated(integrationContract, clientSigningAuthority);
        registryHarness.wrappedSetSigningAuthority(integrationContract, clientSigningAuthority);

        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrationContract),
            clientSigningAuthority,
            "incorrect authority"
        );
    }

    /*//////////////////////////////////////////////////////////////
            _revokeSigningAuthorityForIntegration
    //////////////////////////////////////////////////////////////*/

    // fails when revoking the authority for an integration that does not exist
    function test_RevertsWhen_RevokingAuthorityForNonExistentIntegration() public {
        address integrationContract = _randomAddress();
        vm.expectRevert(ProtocolErrors.Cube3Registry_NonExistentSigningAuthority.selector);
        registryHarness.wrappedRevokeSigningAuthorityForIntegration(integrationContract);
    }
    // succeeds when revoking an existing integration

    function test_RevertsWhen_RevokingAuthorityForIntegration() public {
        address integrationContract = _randomAddress();
        address clientSigningAuthority = _randomAddress();

        registryHarness.wrappedSetSigningAuthority(integrationContract, clientSigningAuthority);
        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrationContract),
            clientSigningAuthority,
            "incorrect authority"
        );

        vm.expectEmit(true, true, true, true);
        emit SigningAuthorityRevoked(integrationContract, clientSigningAuthority);
        registryHarness.wrappedRevokeSigningAuthorityForIntegration(integrationContract);
        assertEq(
            registryHarness.getSignatureAuthorityForIntegration(integrationContract), address(0), "existing authority"
        );
    }
}
