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

contract SignatureModule_Fuzz_Unit_Test is BaseTest {
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
        universalSignerPvtKey = uint256(keccak256(abi.encode((address(_randomAddress())))));
        universalSigner = vm.addr(universalSignerPvtKey);
        signatureModuleHarness = new SignatureModuleHarness(address(mockRouter), "mock-1.0.0", universalSigner, 320);
    }

    modifier asCubeRouter() {
        vm.startPrank(address(mockRouter));
        _;
    }

    // fails when the signing authority is the zero address
    function testFuzz_RevertsWhen_SigningAuthorityNotSet(uint256 pvtKey) public asCubeRouter {
        pvtKey = bound(pvtKey, 1, type(uint128).max);
        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(false, 0, 0, pvtKey);
        vm.expectRevert(ProtocolErrors.Cube3SignatureModule_NullSigningAuthority.selector);
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    // fails when the nonce doesn't match
    function testFuzz_RevertsWhen_UserNonceNotMatching(
        uint256 pvtKey,
        uint256 nonce,
        uint256 incorrectNonce
    )
        public
        asCubeRouter
    {
        pvtKey = bound(pvtKey, 1, type(uint128).max);
        nonce = bound(nonce, 1, type(uint128).max);
        incorrectNonce = bound(incorrectNonce, 1, type(uint128).max);

        vm.assume(nonce != incorrectNonce);

        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(true, nonce, block.timestamp + 1 hours, pvtKey);

        // set the signing authority for the integration
        address authority = vm.addr(pvtKey);
        mockRegistry.setSignatureAuthorityForIntegration(callMetadata.integration, authority);

        // set the incorrect nonce
        signatureModuleHarness.setUserNonce(callMetadata.integration, callMetadata.msgSender, incorrectNonce);
        vm.expectRevert(ProtocolErrors.Cube3SignatureModule_InvalidNonce.selector);
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    // fails when the signing authority is not correct

    // fails when the signature is invalid

    // fails when the timestamp expires
    function testFuzz_RevertsWhen_TimestampHasExpired(uint256 pvtKey, uint256 window) public asCubeRouter {
        pvtKey = bound(pvtKey, 1, type(uint128).max);
        window = bound(window, 1, type(uint40).max);

        uint256 expiresAt = block.timestamp + window;
        vm.warp(expiresAt);

        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(false, 0, expiresAt - 1, pvtKey);

        address authority = vm.addr(pvtKey);
        // set the signing authority for the integration
        mockRegistry.setSignatureAuthorityForIntegration(callMetadata.integration, authority);

        vm.expectRevert(ProtocolErrors.Cube3SignatureModule_ExpiredSignature.selector);
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    // succeeds when:
    // - the signature is valid
    // - the signature authority is used
    // - nonce is tracked and correct
    function testFuzz_SucceedsWhen_SignatureIsValidForSigningAuthority_WithSigAuthorityAndTrackedNonce(
        uint256 pvtKey,
        uint256 nonce
    )
        public
        asCubeRouter
    {
        nonce = bound(nonce, 0, type(uint256).max - 1);
        pvtKey = bound(pvtKey, 1, type(uint128).max);
        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(true, nonce, block.timestamp + 1 hours, pvtKey);

        address authority = vm.addr(pvtKey);

        // set the nonce for the integration
        signatureModuleHarness.setUserNonce(callMetadata.integration, callMetadata.msgSender, nonce);

        // set the signing authority for the integration
        mockRegistry.setSignatureAuthorityForIntegration(callMetadata.integration, authority);

        // validate the signature
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    // succeeds when:
    // - the signature authority is valid
    // - the nonce is or isn't tracked
    function testFuzz_SucceedsWhen_SignatureIsValid_WithNonceOrNoNonce(
        uint256 pvtKey,
        uint256 nonce,
        uint256 window
    )
        public
        asCubeRouter
    {
        nonce = bound(nonce, 3, type(uint256).max - 1);
        pvtKey = bound(pvtKey, 1, type(uint128).max);
        window = bound(window, 1, type(uint40).max);

        bool shouldTrack = nonce % 2 == 0;
        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(shouldTrack, nonce, block.timestamp + window, pvtKey);

        address authority = vm.addr(pvtKey);

        // set the nonce for the integration
        signatureModuleHarness.setUserNonce(callMetadata.integration, callMetadata.msgSender, nonce);

        // set the signing authority for the integration
        mockRegistry.setSignatureAuthorityForIntegration(callMetadata.integration, authority);

        // validate the signature
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    // succeeds when:
    // - the signature is valid
    // - the signature authority is used
    // - nonce is not tracked
    function testFuzz_SucceedsWhen_SignatureIsValidForSigningAuthority_WithSigAuthorityAndNoNonceTracking(
        uint256 pvtKey
    )
        public
        asCubeRouter
    {
        pvtKey = bound(pvtKey, 1, type(uint128).max);
        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(false, 0, block.timestamp + 1 hours, pvtKey);

        address authority = vm.addr(pvtKey);

        // set the signing authority for the integration
        mockRegistry.setSignatureAuthorityForIntegration(callMetadata.integration, authority);

        // validate the signature
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    // succeeds when the signature is valid and the universal signer is used
    function testFuzz_SucceedsWhen_SignatureIsValidForUniversalSigner(uint256 nonce) public asCubeRouter {
        nonce = bound(nonce, 0, type(uint256).max - 1);
        (Structs.TopLevelCallComponents memory callMetadata, bytes memory modulePayload) =
            _generateIntegrationMetadataAndModulePayload(true, nonce, block.timestamp + 1 hours, universalSignerPvtKey);

        // set the nonce for the integration
        signatureModuleHarness.setUserNonce(callMetadata.integration, callMetadata.msgSender, nonce);

        // revoke the registry to trigger the univeral signer
        mockRouter.setRegistryAddress(address(0));

        // validate the signature
        signatureModuleHarness.validateSignature(callMetadata, modulePayload);
    }

    /*//////////////////////////////////////////////////////////////
        HELPERS
    //////////////////////////////////////////////////////////////*/

    function _generateIntegrationMetadataAndModulePayload(
        bool shouldTrackNonce,
        uint256 nonce,
        uint256 expirationTimestamp,
        uint256 pvtKey
    )
        internal
        returns (Structs.TopLevelCallComponents memory, bytes memory)
    {
        // mock the calldata for the integration function call (without the CUBE3 payload)
        bytes memory mockSlicedCalldata = _getRandomBytes(128);

        // create the digest of the "original" function call's selector + args
        bytes32 calldataDigest = keccak256(mockSlicedCalldata);

        // mock the calldata struct
        address integration = _randomAddress();
        address caller = _randomAddress();

        uint256 expectedNonce = shouldTrackNonce ? nonce + 1 : 0;

        Structs.TopLevelCallComponents memory callMetadata = Structs.TopLevelCallComponents({
            msgSender: caller,
            integration: integration,
            msgValue: 0,
            calldataDigest: calldataDigest
        });

        // encode the data and create the signature
        bytes memory signatureData = abi.encode(
            block.chainid,
            callMetadata,
            address(signatureModuleHarness),
            Cube3SignatureModule.validateSignature.selector,
            expectedNonce,
            expirationTimestamp
        );

        bytes memory signature = _createPayloadSignature(signatureData, pvtKey);

        // create the module payload
        bytes memory modulePayload = abi.encodePacked(
            expirationTimestamp,
            shouldTrackNonce, // whether to track the nonce
            expectedNonce,
            signature
        );

        return (callMetadata, modulePayload);
    }
}
