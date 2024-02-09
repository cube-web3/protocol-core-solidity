// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

// TODO: check how others include events, ie interface or contract or lib etc
abstract contract ModuleBaseEvents {
    /// @notice Emitted when a new Cube Module is deployed.
    /// @param routerAddress The address of the Cube3RouterProxy.
    /// @param moduleId The computed ID of the module.
    /// @param version The human-readble module version.
    event ModuleDeployed(address indexed routerAddress, bytes32 indexed moduleId, string indexed version);

    /// @notice Emitted when the module is deprecated.
    /// @param moduleId The computed ID of the module.
    /// @param version  The human-readable module version.
    event ModuleDeprecated(bytes32 indexed moduleId, string indexed version);
}
