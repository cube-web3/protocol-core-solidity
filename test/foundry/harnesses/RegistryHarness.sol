// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Cube3Registry} from "@src/Cube3Registry.sol";

import {Structs} from "@src/common/Structs.sol";

/// @notice Testing harness for the Cube3Registry contract for testing internal and external functions.
contract RegistryHarness is Cube3Registry {
    constructor() Cube3Registry(msg.sender) {}
    function wrappedSetSigningAuthority(address integrationContract, address clientSigningAuthority) external {
        _setClientSigningAuthority(integrationContract, clientSigningAuthority);
    }

    function wrappedRevokeSigningAuthorityForIntegration(address _integration) external {
        _revokeSigningAuthorityForIntegration(_integration);
    }
}
