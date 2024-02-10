// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { ICube3SignatureModule } from "../interfaces/ICube3SignatureModule.sol";
import { ICube3Registry } from "../interfaces/ICube3Registry.sol";
import { ModuleBase } from "./ModuleBase.sol";
import { ProtocolErrors } from "../libs/ProtocolErrors.sol";
import { SignatureUtils } from "../libs/SignatureUtils.sol";
import { Structs } from "../common/Structs.sol";

/// @dev see {ICube3SignatureModule}
/// @dev in the unlikely event that the backup signer is compromised, the module should be deprecated
/// via the router.
contract Cube3SignatureModule is ModuleBase, ICube3SignatureModule {
    // Used to recover the signature from the signature provided.
    using SignatureUtils for bytes;

    // backup signer is used in the cases where the registry has been removed
    // having this as immutable saves gas, but the module will need to be deprecated if the
    // backup signer is compromised
    address private immutable _universalSigner;

    // integration => ( integration msg.sender => nonce)
    mapping(address integration => mapping(address integrationMsgSender => uint256 userNonce)) internal
        integrationToUserNonce;

    event logCube3SignatureModulePayload(SignatureModulePayloadData payload);
    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the Signature module.
    /// @dev Passes the `cubeRouterProxy` address and `version` string to the {Cube3Module} constructor.
    /// @param cube3RouterProxy The address of the Cube3Router proxy.
    /// @param version Human-readable module version used to generate the module's ID
    /// @param backupSigner Backup payload signer in the event the registry is removed
    constructor(
        address cube3RouterProxy,
        string memory version,
        address backupSigner,
        uint256 expectedPayloadSize
    )
        ModuleBase(cube3RouterProxy, version, expectedPayloadSize)
    {
        _universalSigner = backupSigner;
    }

    /*//////////////////////////////////////////////////////////////
            EXTERNAL VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    event log_struct(SignatureModulePayloadData s);
    event stored_log(uint256 n);

    function validateSignature(
        Structs.IntegrationCallMetadata memory integrationData,
        bytes calldata modulePayload
    )
        external
        onlyCube3Router
        returns (bytes32)
    {
        // Fetch the registry address from the router. This will be used later to fetch the signing authority
        // for the integration provided in the {integrationData}.
        ICube3Registry cube3registry = _fetchRegistryFromRouter();

        // If the signing authority returned by the registry is null, then the registry has been removed.
        // In this case, the module will use the backup universal signer.
        address integrationSigningAuthority = address(cube3registry) == address(0)
            ? _universalSigner
            : _fetchSigningAuthorityFromRegistry(cube3registry, integrationData.integration);

        // TODO: Test this
        // Checks that neither the signing authority nor universal signer are null.
        if (integrationSigningAuthority == address(0)) {
            revert ProtocolErrors.Cube3SignatureModule_NullSigningAuthority();
        }

        // Parse the payload provided by the CUBE3 Risk API.
        SignatureModulePayloadData memory signatureModulePayloadData = _decodeModulePayload(modulePayload);
        // emit logCube3SignatureModulePayload(cubeSecuredData);
        emit log_struct(signatureModulePayloadData);
        // If nonce tracking is not required, we expect the payload nonce to be 0
        uint256 expectedUserNonce;

        // Effects: If nonce tracking is disabled, the possibility of replay attacks exists, therefore it is up to the
        // integration to assess the risk.  Nonce tracking is disabled by default in the CUBE3 Risk API and must be
        // explicitly
        // enabled by the integration owner. If nonce tracking is enabled, and the nonce is incremented, we intenionally
        // omit an event to lower the function's gas usage.
        if (signatureModulePayloadData.shouldTrackNonce) {
            // no user can feasibly get close to type(uint256).max nonces, so use unchecked math.
            unchecked {
                // First increments the `integrationToUserNonce` storage variable, then sets the in-memory {userNonce}.
                expectedUserNonce = ++integrationToUserNonce[integrationData.integration][integrationData.msgSender];
            }
            emit stored_log(expectedUserNonce);
            // TODO: Add an event
            // TODO: Test
            // Checks: the cube3SecuredData.nonce should equal: user's nonce at the time of the tx + 1
            if (signatureModulePayloadData.nonce != expectedUserNonce) {
                revert ProtocolErrors.Cube3SignatureModule_InvalidNonce();
            }
        }

        // Checks: recover the signer from the signature and compare to the signing authority fetched from the
        // registry. The first param passed to {_recoverSigner} is the reconstructed chain data that was used
        // when creating the signature.
        bytes32 signatureDigest = keccak256(
            abi.encode(
                // Utilize the chainid, which is included to prevent replay attacks across different chains.
                _getChainID(),
                // Includes the integration's: address, msg.sender, msg.value, and a hash of the
                // integration's calldata (which excludes the CUBE3 payload).
                integrationData,
                // Including the module's contract address ensures the payload is intended for this module.
                address(this),
                // If a module exposes funcitonality via different functions, ensure the correct one is used.
                msg.sig,
                // If shouldTrackNonce is false, nonce is expected to be zero.
                expectedUserNonce,
                // The block timestamp after which the signature is no longer considered valid.
                signatureModulePayloadData.expirationTimestamp
            )
        );

        // Checks: asserts that the signing authority provided matches the signer
        // recovered from the signature. If the signature is invalid, the call will revert.
        signatureModulePayloadData.signature.assertIsValidSignature(signatureDigest, integrationSigningAuthority);

        // Interactions: The signer was successfully recovered, so we inform the Router
        // to proceed with the integration's function call.
        return MODULE_CALL_SUCCEEDED;
    }

    /*//////////////////////////////////////////////////////////////
            EXTERNAL CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function integrationUserNonce(address integrationContract, address account) external view returns (uint256) {
        return integrationToUserNonce[integrationContract][account];
    }

    /*//////////////////////////////////////////////////////////////
            EXTERNAL CALL WRAPPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Utility function for retrieving the signing authority from the registry for a given integration
    function _fetchSigningAuthorityFromRegistry(
        ICube3Registry cube3registry,
        address integration
    )
        internal
        view
        returns (address signer)
    {
        signer = cube3registry.getSignatureAuthorityForIntegration(integration);
    }

    /// @dev Makes an external call to the Cube3Router to retrieve the registry address.
    function _fetchRegistryFromRouter() internal view returns (ICube3Registry) {
        return ICube3Registry(cube3router.getRegistryAddress());
    }

    /*//////////////////////////////////////////////////////////////
            INTERNAL PAYLOAD UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _getChainID() internal view returns (uint256 id) {
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
    }

    /// @dev Utility function for decoding the `cube3SecurePayload` and returning its
    ///      constituent elements as a SignatureModulePayloadData struct.
    /// @dev Checks the validity of the payloads target function selector, module Id, and expiration.
    /// @param modulePayload The module payload to decode, created with abi.encodePacked().
    function _decodeModulePayload(bytes calldata modulePayload)
        internal
        view
        returns (SignatureModulePayloadData memory)
    {
        // Extract the uint256 timestamp from the first word.
        uint256 expirationTimestamp = uint256(bytes32(modulePayload[:32]));

        // Extract the bool that dictates whether to check the nonce from the signle byte
        // that follows the expiration timestamp.
        // bool shouldTrackNonce = uint256(bytes32(modulePayload[32:33])) == 1;
        bool shouldTrackNonce = modulePayload[32] == 0x01;

        // Extract the uint256 nonce from the next 32 bytes.
        uint256 nonce = uint256(bytes32(modulePayload[33:65]));

        // Extract the signature from the remaining bytes. There's no need to check the length
        // of the signature as it will be checked when the signer is recovered.
        bytes memory signature = modulePayload[65:];

        // TODO: test this
        // Checks: the expiration timestamp should be in the future.
        if (expirationTimestamp <= block.timestamp) {
            revert ProtocolErrors.Cube3SignatureModule_ExpiredSignature();
        }

        // Return the data as the payload struct.
        return SignatureModulePayloadData(expirationTimestamp, shouldTrackNonce, nonce, signature);
    }
}
