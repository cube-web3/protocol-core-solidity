// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Structs} from "@src/common/Structs.sol";

/// @title ICube3RouterImpl
/// @notice Contains the collective logic for the {Cube3RouterImpl} contract and the contracts it inherits from:
/// {ProtocolManagement}, {IntegrationManagement}, and {RouterStorage}.
/// @dev All events are defined in {ProtocolEvents}.
interface ICube3RouterImpl {
    /*//////////////////////////////////////////////////////////////////////////
                            CUBE3 Router Implementation
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Used to retrieve the implementation address of the proxy.
    /// @dev Utilizes {ERC1967Utils-getImplementation}
    /// @return The address of the implementation contract.
    function getImplementation() external view returns (address);

    /// @notice Initializes the proxy contract.
    ///
    /// @dev Emits a {ProtocolConfigUpdated} event.
    ///
    /// Notes:
    /// - Initializes AccessControlUpgradeable
    /// - Initialized UUPSUpgradeable
    /// - Initializes ERC165
    /// - Sets the initial configuration of the protocol.
    /// - Sets the DEFAULT_ADMIN_ROLE explicitly. This accounts
    /// for deployment using salted contract creation via a contract.
    /// - The protocol is not paused by default.
    ///
    /// Requirements:
    /// - `msg.sender` must be a contract and the call must take place within it's constructor.
    /// - `registry` cannot be the zero address.
    ///
    /// @param registry The address of the CUBE3 Registry contract.
    /// @param initialAdmin The address of the CUBE3 Protocol Admin.
    function initialize(address registry, address initialAdmin) external;

    /// @notice Routes the top-level calldata to the Security Module using data
    /// embedded in the routing bitmap.
    ///
    /// @dev If events are emitted, they're done so by the Security Module being utilized.
    ///
    /// Notes:
    /// - Acts like an assertion.  Will revert on any error or failure to meet the
    /// conditions laid out by the security module.
    /// - Will bypass the security modules under the following conditions, checked
    /// sequentially:
    ///     - Function protection for the provided selector is disabled.
    ///     - The integration's registration status is revoked.
    ///     - The Protocol is paused.
    /// - Only contracts can be registered as integrations, so checking against UNREGISTERED
    /// status is redundant.
    /// - No Ether is transferred to the router, so the function is non-payable.
    /// - If the module function call reverts, the revert data will be relayed to the integration.
    ///
    /// Requirements:
    /// - The last word of the `integrationCalldata` is a valid routing bitmap.
    /// - The module identified in the routing bitmap must be installed.
    /// - The call to the Security Module must succeed.
    ///
    /// @param integrationMsgSender the `msg.sender` of the top-level call.
    /// @param integrationMsgValue The `msg.value` of the top-level call.
    /// @param integrationCalldata The `msg.data` of the top-level call, which includes the
    /// CUBE3 Payload.
    ///
    /// @return The PROCEED_WITH_CALL magic value if the call succeeds.
    function routeToModule(
        address integrationMsgSender,
        uint256 integrationMsgValue,
        bytes calldata integrationCalldata
    ) external returns (bytes32);

    /// @notice Checks whether the ICube3Router interface is supported.
    /// @param interfaceId The interfaceId to check.
    /// @return Whether the provided interface is supported: `true` for yes.
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
