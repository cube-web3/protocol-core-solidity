// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Structs } from "@src/common/Structs.sol";

/// @title IRouterStorage
/// @notice Contains the dedicated getter functions for accessing the Router's storage.
interface IRouterStorage {

    /// @notice Gets the protection status of an integration contract's function using the selector.
    /// @param integration The address of the integration contract to check the function protection status for.
    /// @param fnSelector The function selector to check the protection status for.
    function getIsIntegrationFunctionProtected(address integration, bytes4 fnSelector) external view returns (bool);

    /// @notice Gets the registration status of the integration provided.
    /// @param integration The address of the integration contract to check the registration status for.
    /// @return The registration status of the integration.
    function getIntegrationStatus(address integration) external view returns (Structs.RegistrationStatusEnum);

    /// @notice Gets the pending admin account for the `integration` provided.
    /// @param integration The address of the integration contract to check the pending admin for.
    /// @return The pending admin account for the integration.
    function getIntegrationPendingAdmin(address integration) external view returns (address);

    /// @notice Gets the admin account for the `integration` provided.
    /// @param integration The address of the integration contract to retrieve the admin for.
    /// @return The admin account for the integration.
    function getIntegrationAdmin(address integration) external view returns (address);

    /// @notice Gets whether the protocol is paused.
    /// @return True if the protocol is paused.
    function getIsProtocolPaused() external view returns (bool);

    /// @notice Gets the contract address of a module using its computed Id.
    /// @param moduleId The module's ID derived from the hash of the module's version string.
    /// @return The module contract's address.
    function getModuleAddressById(bytes16 moduleId) external view returns (address);

    /// @notice Returns whether or not the given signature hash has been used before.
    /// @param signatureHash The hash of the signature to check.
    /// @return True if the signature hash has been used before.
    function getRegistrarSignatureHashExists(bytes32 signatureHash) external view returns (bool);

    /// @notice Gets the current protocol configuration.
    /// @return The current protocol configuration object containing the registry address and paused state.
    function getProtocolConfig() external view returns (Structs.ProtocolConfig memory);

    /// @notice Gets the contract address of the CUBE3 Registry.
    /// @return The contract address of the CUBE3 Registry.
    function getRegistryAddress() external view returns (address);

    /// @notice Returns whether or not the given module has been deprecated.
    /// @param moduleId The module's ID derived from the hash of the module's version string.
    /// @return True if the module has been deprecated.
    function getIsModuleVersionDeprecated(bytes16 moduleId) external view returns (bool);
}
