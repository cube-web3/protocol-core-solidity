// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Structs } from "@src/common/Structs.sol";

/// @title ICube3SignatureModule
/// @notice Cube3 Runtime Application Self-Protection (RASP) module for signature verification and
/// data validation.  The module is responsible for verifying that the payload received by the module was
/// generated by the Cube3 Risk API, and that the data it contains can be validated by recovering
///  the signing authority from the signature and the on-chain data.
/// @dev Inherits core module functionality from the Cube3Module contract.
/// @dev Module emits no events as a gas-saving measure.
interface ICube3SignatureModule {
    /*//////////////////////////////////////////////////////////////
            DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Defines the structure of the Signature Module Payload, ie the data expected by this module.
    /// @dev This Module Payload is included in the CUBE3 Payload that's passed to the {ProtectionBase-cube3Protected}
    /// modifier.
    /// @param expirationTimestamp The block timestamp up until which the payload is considered valid.
    /// @param shouldTrackNonce A boolean value dictating whether or no the transaction nonce should
    /// be accounted for.
    /// @param nonce The transaction nonce for the caller. Will be 0 if `shouldTrackNonce` is `false`.
    /// @param signature ECDSA signature generated by the integration's signing authority.
    struct SignatureModulePayloadData {
        uint256 expirationTimestamp;
        bool shouldTrackNonce;
        uint256 nonce;
        bytes signature;
    }

    /*//////////////////////////////////////////////////////////////
            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Validates the signature and data signed by the Integration's
    /// signing authority.
    ///
    /// @dev Emits no events as a gas-saving measure.
    ///
    /// Notes:
    /// - If the Registry has been removed from the Router, the module will fallback
    /// to using the backup universal signer.
    /// - Acts like an assertion, will revert under any condition except success.
    ///
    /// Requirements:
    /// - `msg.sender` must be the CUBE3 Router.
    /// - The integration's signing authority cannot be the zero address.
    /// - The signer recoverd from the signature must match the Integration's signing
    /// authority.
    /// - The payload's expiration timestamp must not exceed the current block.timestamp.
    ///
    /// @param topLevelCallComponents The details of the top-level call, such as `msg.sender`
    /// @param signatureModulePayload The payload containing the data to be validated by this module.s
    ///
    /// @return The hashed MODULE_CALL_SUCCEEDED indicating that signature recovery was succeefull.
    function validateSignature(
        Structs.TopLevelCallComponents memory topLevelCallComponents,
        bytes calldata signatureModulePayload
    ) external returns (bytes32);

    /// @notice Retrieves the per-integration nonce of the `account` provided
    /// @dev The nonce will only be incremented if directed by the module payload.
    /// @param integrationContract The integration to retrieve the nonce for.
    /// @param account The address of the caller to retrieve the nonce for.
    function integrationUserNonce(address integrationContract, address account) external view returns (uint256);
}
