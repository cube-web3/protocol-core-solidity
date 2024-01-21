// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Structs} from "../common/Structs.sol";

/// @title Cube3 Signature Module.
/// @author CUBE3.ai
/// @notice Cube3 Runtime Application Self-Protection (RASP) module for signature verification and
///         data validation.  The module is responsible for verifying that the payload received by the module was
///         generated by the Cube3 Risk API, and that the data it contains can be validated by recovering
///         the signing authority from the signature and the on-chain data.
/// @dev Inherits core module functionality from the Cube3Module contract.
/// @dev There's no access control implemented as no functionality requires elevated privileges.
/// @dev Module emits no events as a gas-saving measure.

interface ICube3SignatureModule {
    /*//////////////////////////////////////////////////////////////
            DATA STRUCTURES
    //////////////////////////////////////////////////////////////*/

    /// @notice Defines the structure of the cube3SecurePayload and its contents for the Cube3 Signature Module.
    /// @dev The `cube3SecurePayload` is passed in as function parameter to all Cube3Integration integration functions.
    struct Cube3SignatureModulePayload {
        uint256 expirationTimestamp;
        bool shouldTrackNonce;
        uint256 nonce;
        bytes signature;
    }

    /*//////////////////////////////////////////////////////////////
            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function validateSignature(Structs.IntegrationCallMetadata memory integrationData, bytes calldata cube3SecurePayload)
        external
        returns (bytes32);

    /*//////////////////////////////////////////////////////////////
            EVENTS
    //////////////////////////////////////////////////////////////*/
    event RegistryUpdated(address indexed newRegistry, address indexed deprecatedRegistry);
}
