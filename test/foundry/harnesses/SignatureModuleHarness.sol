// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Cube3SignatureModule} from "@src/modules/Cube3SignatureModule.sol";
import {ICube3Registry} from "@src/interfaces/ICube3Registry.sol";

contract SignatureModuleHarness is Cube3SignatureModule {
    constructor(
        address cube3RouterProxy,
        string memory version,
        address backupSigner
    ) Cube3SignatureModule(cube3RouterProxy, version, backupSigner) {}

    function setUserNonce(address integration, address caller, uint256 nonce) public {
        integrationToUserNonce[integration][caller] = nonce;
    }

    function fetchSigningAuthorityFromRegistry(
        ICube3Registry cube3registry,
        address integration
    ) public view returns (address) {
        return _fetchSigningAuthorityFromRegistry(cube3registry, integration);
    }

    function fetchRegistryFromRouter() public view returns (ICube3Registry) {
        return _fetchRegistryFromRouter();
    }

    function getChainID() public view returns (uint256) {
        return _getChainID();
    }

    function decodeModulePayload(bytes calldata modulePayload) public view returns (SignatureModulePayloadData memory) {
        return _decodeModulePayload(modulePayload);
    }
}
