// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ICube3Registry } from "../../../../src/interfaces/ICube3Registry.sol";
import { SignatureModuleHarness } from "../../harnesses/SignatureModuleHarness.sol";
import { MockRegistry } from "../../../mocks/MockRegistry.t.sol";
import { MockRouter } from "../../../mocks/MockRouter.t.sol";
import { BaseTest } from "../../BaseTest.t.sol";
import { ProtocolErrors } from "../../../../src/libs/ProtocolErrors.sol";
import { Structs } from "../../../../src/common/Structs.sol";
import { Cube3SignatureModule } from "../../../../src/modules/Cube3SignatureModule.sol";

contract SignatureModule_Concrete_Unit_Test is BaseTest {
    SignatureModuleHarness signatureModuleHarness;
    MockRouter mockRouter;
    MockRegistry mockRegistry;

    uint256 uinversalSignerPvtKey;
    address universalSigner;

    uint256 signingAuthorityPrivateKey;
    address signingAuthority;

    uint256 nonceSeed;

    function setUp() public override {
        mockRouter = new MockRouter();
        mockRegistry = new MockRegistry();
        mockRouter.setRegistryAddress(address(mockRegistry));
        signatureModuleHarness = new SignatureModuleHarness(address(mockRouter), "mock-1.0.0", universalSigner, 320);
    }

    modifier asCubeRouter() {
        vm.startPrank(address(mockRouter));
        _;
    }

    // succeeds when fetching the remote signing authority from the registry
    function test_SucceedsWhen_FetchingSigningAuthorityFromRegistry() public {
        address integration = _randomAddress();
        mockRegistry.setSignatureAuthorityForIntegration(integration, signingAuthority);
        assertEq(
            signatureModuleHarness.fetchSigningAuthorityFromRegistry(ICube3Registry(address(mockRegistry)), integration),
            signingAuthority,
            "authority not matching"
        );
    }

    // succeeds when fetching the registry from the router
    function test_SucceedsWhen_FetchingRegistryFromTheRouter() public {
        assertEq(
            address(signatureModuleHarness.fetchRegistryFromRouter()), address(mockRegistry), "registry not matching"
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
