// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {ICube3SignatureModule} from "../interfaces/ICube3SignatureModule.sol";
import {ICube3Registry} from "../interfaces/ICube3Registry.sol";
import {ModuleBase} from "./ModuleBase.sol";

import {Structs} from "../common/Structs.sol";

/// @dev see {ICube3SignatureModule}
/// @dev in the unlikely event that the backup signer is compromised, the module should be deprecated
/// via the router.
contract Cube3SignatureModule is ModuleBase, ICube3SignatureModule {
    // used ECDSA to recover the signature's signing authority
    using ECDSA for bytes32;

    // backup signer is used in the cases where the registry has been removed
    // having this as immutable saves gas, but the module will need to be deprecated if the
    // backup signer is compromised
    address private immutable _backupSigner;

    // stores the caller's (EOA) integration- and module-specific nonce
    mapping(address => mapping(address => uint256)) private integrationToUserNonce; //contract => (user account => nonce)


    event logCube3SignatureModulePayload(Cube3SignatureModulePayload payload);
    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the Signature module.
    /// @dev Passes the `cubeRouterProxy` address and `version` string to the {Cube3Module} constructor.
    /// @param cube3RouterProxy The address of the Cube3Router proxy.
    /// @param version Human-readable module version used to generate the module's ID
    /// @param backupSigner Backup payload signer in the event the registry is removed
    constructor(address cube3RouterProxy, string memory version, address backupSigner, uint256 expectedPayloadSize)
        ModuleBase(cube3RouterProxy, version, expectedPayloadSize)
    {
        _backupSigner = backupSigner;
    }

    /*//////////////////////////////////////////////////////////////
            EXTERNAL VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function validateSignature(Structs.IntegrationCallMetadata memory integrationData, bytes calldata modulePayload)
        external
        onlyCube3Router
        returns (bytes32)
    {

        // Fetch the registry address from the router. This will be used later to fetch the signing authority
        // for the integration provided in the {integrationData}.
        ICube3Registry cube3registry = _getRegistryFromRouter();

        address integrationSigningAuthority = address(cube3registry) == address(0)
            ? _backupSigner
            : _getSigningAuthority(cube3registry, integrationData.integration);

        require(integrationSigningAuthority != address(0), "SM02: invalid authority");

        // Effects: deconstruct the payload provided by the CUBE3 Risk API
        Cube3SignatureModulePayload memory cubeSecuredData = _decodeModulePayload(modulePayload);
        // emit logCube3SignatureModulePayload(cubeSecuredData);
        
        // If nonce tracking is not required, we expect the payload nonce to be 0
        uint256 userNonce;

        // Effects: If nonce tracking is disabled, the possibility of replay attacks exists, therefore it is up to the integration
        // to assess the risk.  Nonce tracking is disabled by default in the CUBE3 Risk API and must be explicitly enabled by the integration owner.
        // note: If nonce tracking is enabled, and the nonce is incremented, we intenionally omit an event to lower the function's gas usage.
        if (cubeSecuredData.shouldTrackNonce) {
            // no user can feasibly get close to type(uint256).max nonces, so use unchecked math.
            unchecked {
                // First increments the {integrationToUserNonce} storage variable, then sets the in-memory {userNonce}.
                userNonce = ++integrationToUserNonce[integrationData.integration][integrationData.msgSender];
            }

            // Checks: the cube3SecuredData.nonce should equal: user's nonce at the time of the tx + 1
            require(cubeSecuredData.nonce == userNonce, "SM03: invalid nonce");
        }

        // Effects: recover the signer from the signature and compare to the signing authority fetched from the registry.
        // The first param passed to {_recoverSigner} is the reconstructed chain data that was used when creating the signature.
        if (
            _recoverSigner(
                abi.encode(
                    _getChainID(), // chainid
                    integrationData, // includes the integration's: address, msg.sender, msg.value, and a hash of the calldata (less the module payload)
                    address(this), // module contract address
                    msg.sig, // module's target function selector
                    userNonce, // if shouldTrackNonce is false, nonce will be zero
                    cubeSecuredData.expirationTimestamp
                ),
                cubeSecuredData.signature, // comes from cube3SecurePayload
                integrationSigningAuthority // retrieved from registry
            )
        ) {
            // Interactions: The signer was successfully recovered, so we can proceed with the integration's function call.
            return MODULE_CALL_SUCCEEDED;
        } else {
            // Interactions: Let the router know that the signature recovery failed, which will trigger a revert in the router.
            return MODULE_CALL_FAILED;
        }
    }

    /*//////////////////////////////////////////////////////////////
            EXTERNAL CONVENIENCE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function integrationUserNonce(address integrationContract, address account) external view returns (uint256) {
        return integrationToUserNonce[integrationContract][account];
    }

    /*//////////////////////////////////////////////////////////////
            INTERNAL SIGNATURE UTILITIES
    //////////////////////////////////////////////////////////////*/

    function _getChainID() private view returns (uint256 id) {
        /* solhint-disable no-inline-assembly */
        assembly {
            id := chainid()
        }
    }

    /// @notice Validates the signature by comparing the recovered address to the signing authority retrieved from the registry.
    /// @dev {toEthSignedMessageHash} replicates the behavior of eth_sign.
    /// @dev Will revert if the recovered address does not match the signing authority retrieved from the registry.
    /// @param reconstructedChainData Reconstructed data, using on-chain data, to hash and attempt address recovery.
    /// @param signature The bytes signature of length 65 of abi.encodePacked(r,s,v).
    /// @param _signingAuthority The signing authority address retrieved from the Cube3Registry.
    /// @return True if the recovery was successful.
    function _recoverSigner(bytes memory reconstructedChainData, bytes memory signature, address _signingAuthority)
        private
        pure
        returns (bool)
    {
        bytes32 signedHash = keccak256(reconstructedChainData);
        bytes32 ethSignedHash = signedHash.toEthSignedMessageHash();
        // `tryRecover` returns ECDSA.RecoverError error as the second return value, but we don't need
        // to evaluate as any error returned will return address(0) as the first return value
        // the `payloadSigner` is the integration's signing authority public address stored in the CUBE3 KMS
        (address payloadSigner,) = ethSignedHash.tryRecover(signature); // 3k gas

        // check the payload signer is not the zero address, which can happen when the signature contains empty bytes.
        require(payloadSigner != address(0), "SM04: invalid signer");

        // Check that the account that created the signature matches the signing authority retrieved from the registry.
        require(payloadSigner == _signingAuthority, "SM05: invalid signer");

        // Return that the recovery process was successful.
        return true;
    }

    /// @dev Utility function for retrieving the signing authority from the registry for a given integration
    function _getSigningAuthority(ICube3Registry cube3registry, address integration)
        private
        view
        returns (address signer)
    {
        signer = cube3registry.getSignatureAuthorityForIntegration(integration);
    }

    /// @dev Makes an external call to the Cube3Router to retrieve the registry address.
    function _getRegistryFromRouter() private view returns (ICube3Registry) {
        return ICube3Registry(cube3router.getRegistryAddress());
    }

    /*//////////////////////////////////////////////////////////////
            INTERNAL PAYLOAD UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @dev Utility function for decoding the `cube3SecurePayload` and returning its
    ///      constituent elements in the Cube3SignatureModulePayload struct.
    /// @dev Checks the validity of the payloads target function selector, module Id, and expiration
    function _decodeModulePayload(bytes calldata modulePayload)
        private
        view
        returns (Cube3SignatureModulePayload memory deconstructedPayload)
    {
        uint256 expirationTimestamp = uint256(bytes32(modulePayload[:32]));
        bool shouldTrackNonce = uint256(bytes32(modulePayload[32:33])) == 1;
        uint256 nonce = uint256(bytes32(modulePayload[33:65]));
        bytes memory signature = modulePayload[65:];

        require(expirationTimestamp > block.timestamp, "SM08: signature expired");

        deconstructedPayload = Cube3SignatureModulePayload(
            expirationTimestamp, shouldTrackNonce, nonce, signature
        );
    }
}
