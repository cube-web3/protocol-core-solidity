// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Structs } from "./Structs.sol";

contract ProtocolEvents {
    /// @notice Emitted when an integration's revocation status is updated.
    /// @dev Recovation status will be {True} when the integration is revoked and {False} when the revocation is cleared
    /// @param integration The integration contract whose revocation status is updated.
    /// @param isRevoked Whether the `integration` contract is revoked.
    event IntegrationRegistrationRevocationStatusUpdated(address indexed integration, bool isRevoked);

    /// @notice Emitted when a Cube3 admin installs a new module.
    /// @param moduleId The module's computed ID.
    /// @param moduleAddress The contract address of the module.
    /// @param version A string representing the modules version in the form `<module_name>-<semantic_version>`.
    event RouterModuleInstalled(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);

    /// @notice Emitted when a Cube3 admin deprecates an installed module.
    /// @param moduleId The computed ID of the module that was deprecated.
    /// @param moduleAddress The contract address of the module that was deprecated.
    /// @param version The human-readable version of the deprecated module.
    event RouterModuleDeprecated(bytes32 indexed moduleId, address indexed moduleAddress, string indexed version);

    event Cube3ProtocolContractsUpdated(address indexed gateKeeper, address indexed registry);

    event UsedRegistrationSignatureHash(bytes32 indexed hash);

    /*//////////////////////////////////////////////////////////////
            EVENTS
    //////////////////////////////////////////////////////////////*/

    event IntegrationRegistrationStatusUpdated(address indexed integration, Structs.RegistrationStatusEnum status);
    event IntegrationAdminUpdated(address indexed integration, address indexed admin);
    event IntegrationPendingAdminRemoved(address indexed integration, address indexed pendingAdmin);
    event IntegrationAdminTransferStarted(address indexed integration, address indexed oldAdmin, address indexed pendingAdmin);
    event IntegrationAdminTransferred(address indexed integration, address indexed oldAdmin, address indexed newAdmin);
    event FunctionProtectionStatusUpdated(address indexed integration, bytes4 indexed selector, bool status);
    event ProtocolConfigUpdated(address indexed registry, bool paused);

    event InitiateReg(address integration, Structs.IntegrationState state);
    event LogModuleSelector(bytes4 s);
    event LogModuleId(bytes32 id);
    event LogPayload(bytes b);
    event LogDataHash(bytes32 h);
    event LogInt(uint256 u);
    event LogDigsest(bytes32 d);
    event LogMsgData(bytes m);
}
