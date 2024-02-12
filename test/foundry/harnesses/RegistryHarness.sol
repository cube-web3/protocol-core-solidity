// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.19 < 0.8.24;

import { Cube3Registry } from "@src/Cube3Registry.sol";

import { Structs } from "@src/common/Structs.sol";

/// @notice Testing harness for the Cube3Registry contract for testing internal and external functions.
contract RegistryHarness is Cube3Registry {
    function wrappedSetSigningAuthority(address integrationContract, address clientSigningAuthority) external {
        _setClientSigningAuthority(integrationContract, clientSigningAuthority);
    }

    function wrappedRevokeSigningAuthorityForIntegration(address _integration) external {
        _revokeSigningAuthorityForIntegration(_integration);
    }
}
