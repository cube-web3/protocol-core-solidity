// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

// TODO: rename ICube3SecurityModule.

/// @title ICube3Module
/// @notice Provides an interface for the functionality shared by all CUBE3 Security Modules.
///
/// Notes:
/// - All CUBE3 security modules will inherit this base contract.
/// - This contract is used through inheritance only.
/// - Any module that inherits this contract should never make use of `selfdestruct` or
/// delegatecall to a contract that might, as it could potentially render the router proxy
/// inoperable.
/// - Events are defined in {ModuleBaseEvents}
interface ICube3Module {
    /// @notice Deprecates the module so that it cannot be used or reinstalled.
    ///
    /// @dev Emits a {ModuleDeprecated} event.
    ///
    /// Notes:
    /// - Can be overridden in the event additional logic needs to be executed during deprecation. The overriding
    /// function MUST use `onlyCube3Router` modifier to ensure access control mechanisms are applied.
    /// Once a module has been deprecated it cannot be reinstalled in the router.
    ///
    /// Requirements:
    /// - `msg.sender` is the CUBE3 Router contract.
    ///
    /// @return The version string of the module.
    function deprecate() external returns (string memory);

    /*//////////////////////////////////////////////////////////////
            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice The human-readable version of the module.
    /// @dev Module version scheme is as follows: `<module_name>-<semantic_version>`, eg. `signature-0.0.1`
    /// Validation of the moduleVersion string must be done by the deployer
    /// @return The module version as a string
    function moduleVersion() external view returns (string memory);

    /// @notice Indicates whether the module has been deprecated.
    /// @return The deprecation status of the module
    function isDeprecated() external view returns (bool);

    /// @notice Gets the ID of the module.
    /// @dev Computes the keccak256 hash of the abi.encoded moduleVersion in storage.
    /// @return The module's computed ID.
    function moduleId() external view returns (bytes16);

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/

    /// @notice Checks if the contract implements an interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165.
    /// @return bool `true` if the contract implements `interfaceId`, `false` otherwise.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
