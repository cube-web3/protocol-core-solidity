// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ICube3Registry} from "@src/interfaces/ICube3Registry.sol";
import {SignatureModuleHarness} from "@test/foundry/harnesses/SignatureModuleHarness.sol";
import {MockRegistry} from "@test/mocks/MockRegistry.t.sol";
import {MockRouter} from "@test/mocks/MockRouter.t.sol";
import {BaseTest} from "@test/foundry/BaseTest.t.sol";
import {ProtocolErrors} from "@src/libs/ProtocolErrors.sol";
import {Structs} from "@src/common/Structs.sol";
import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";

contract SignatureModule_Concrete_Unit_Test is BaseTest {
    SignatureModuleHarness signatureModuleHarness;
    MockRouter mockRouter;
    MockRegistry mockRegistry;

    uint256 universalSignerPvtKey;
    address universalSigner;

    uint256 signingAuthorityPrivateKey;
    address signingAuthority;

    uint256 nonceSeed;

    function setUp() public override {
        mockRouter = new MockRouter();
        mockRegistry = new MockRegistry();
        mockRouter.setRegistryAddress(address(mockRegistry));
        universalSignerPvtKey = uint256(keccak256("universalSigner"));
        universalSigner = vm.addr(universalSignerPvtKey);
        signatureModuleHarness = new SignatureModuleHarness(address(mockRouter), "mock-1.0.0", universalSigner);
    }

    modifier asCubeRouter() {
        vm.startPrank(address(mockRouter));
        _;
    }

    // Reverts when setting the universal signer as the zero address on deployment
    function test_RevertsWhen_SettingUniversalSignerAsNull() public {
        vm.expectRevert(ProtocolErrors.Cube3Registry_NullUniversalSigner.selector);
        SignatureModuleHarness altSigModule = new SignatureModuleHarness(address(mockRouter), "mock-1.0.0", address(0));
        (altSigModule);
    }

    // succeeds when fetching the remote signing authority from the registry
    function test_SucceedsWhen_FetchingSigningAuthorityFromRegistry() public {
        address integration = _randomAddress();
        mockRegistry.setSignatureAuthorityForIntegration(integration, signingAuthority);
        assertEq(
            signatureModuleHarness.fetchSigningAuthorityFromRegistry(
                ICube3Registry(address(mockRegistry)),
                integration
            ),
            signingAuthority,
            "authority not matching"
        );
    }

    // succeeds when fetching the registry from the router
    function test_SucceedsWhen_FetchingRegistryFromTheRouter() public {
        assertEq(
            address(signatureModuleHarness.fetchRegistryFromRouter()),
            address(mockRegistry),
            "registry not matching"
        );
    }

    // succeeds when returning the correct chain id
    function test_SucceedsWhen_ReturningCorrectChainID() public {
        assertEq(block.chainid, signatureModuleHarness.getChainID(), "chain id not matching");
    }

    // succeeds setting and fetching the user nonce
    function test_SucceedsWhen_FetchingUserNonce() public {
        uint256 nonce = 42_069;
        address integration = _randomAddress();
        address user = _randomAddress();
        signatureModuleHarness.setUserNonce(integration, user, nonce);
        assertEq(signatureModuleHarness.integrationUserNonce(integration, user), nonce, "nonce not matching");
    }
}
