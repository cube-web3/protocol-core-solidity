// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;
import { Structs } from "@src/common/Structs.sol";

/// @title IProtocolManagement
/// @notice Contains the logic for privileged accounts belonging to CUBE3 to configure the protocol and
/// Security Modules.
interface IProtocolManagement {

    /// @notice Updates the protocol configuration.
    ///
    /// @dev Emits {ProtocolConfigUpdated} and conditionally {ProtocolRegistryRemoved} events
    ///
    /// Notes:
    /// - We allow the registry to be set to the zero address in the event of a compromised KMS. This will
    /// prevent any new integrations from being registered until the Registry contract is replaced.
    /// - Allows a Protocol Admin to update the Registry and pause the protocol.
    /// - Pausing the protocol prevents new registrations and will force all calls to {Cube3RouterImpl-routeToModule}
    /// to return early.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.
    /// - If not the zero address, the smart contract at `registry` must support the ICube3Registry interface.
    ///
    /// @param registry The address of the Cube3Registry contract.
    /// @param isPaused Whether the protocol is paused or not.
    function updateProtocolConfig(address registry, bool isPaused) external;

    /// @notice Calls a function using the calldata provided on the given module.
    ///
    /// @dev Emits any events emitted by the module function being called.
    ///
    /// Notes:
    /// - Used to call privileged functions on modules where only the router has access.
    /// - Acts similar to a proxy, except uses `call` instead of `delegatecall`.
    /// - The module address is retrived from storage using the `moduleId`.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE.
    /// - The module represented by `moduleId` must be installed.
    ///
    /// @param moduleId The ID of the module to call the function on.
    /// @param fnCalldata The calldata for the function to call on the module.
    ///
    /// @return The return or revert data from the module function call.
    function callModuleFunctionAsAdmin(
        bytes16 moduleId,
        bytes calldata fnCalldata
    )
        external
        payable
        returns (bytes memory);

    /// @notice Adds a new module to the Protocol.
    ///
    /// @dev Emits an {RouterModuleInstalled} event.
    ///
    /// Notes:
    /// - Module IDs are included in the routing bitmap at the tail of the `cube3Payload` and
    /// and are used to dynamically retrieve the contract address for the destination module from storage.
    /// - The Router can only make calls to modules registered via this function.
    /// - Can only install module contracts that have been deployed and support the {ICube3SecurityModule} interface.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE role.
    /// - The `moduleAddress` cannot be the zero address.
    /// - The `moduleAddress` must be a smart contract that supports the ICube3SecurityModule interface.
    /// - The `moduleId` must not contain empty bytes or have been installed before.
    /// - The `moduleId` provided must match the hash of the version string stored in the module contract.
    /// - The module must not have previously been deprecated.
    ///
    /// @param moduleAddress The contract address where the module is located.
    /// @param moduleId The corresponding module ID generated from the hash of its version string.
    function installModule(address moduleAddress, bytes16 moduleId) external;

    /// @notice Deprecates an installed module.
    ///
    /// @dev Emits {RouterModuleDeprecated} and {RouterModuleRemoved} events.
    ///
    /// Notes:
    /// - Deprecation removes the `moduleId` from the list of active modules and adds its to a list
    /// of deprecated modules that ensures it cannot be re-installed.
    /// - If a module is accidentally deprecated, it can be re-installed with a new version string.
    ///
    /// Requirements:
    /// - `msg.sender` must possess the CUBE3_PROTOCOL_ADMIN_ROLE role.
    /// - The module must currently be installed.
    /// - The call to the {deprecate} function on the module must succeed.
    ///
    /// @param moduleId The module ID of the module to deprecate.
    function deprecateModule(bytes16 moduleId) external;
}
