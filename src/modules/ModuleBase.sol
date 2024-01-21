// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {ICube3Router} from "../interfaces/ICube3Router.sol";
import {ICube3Module} from "../interfaces/ICube3Module.sol";

/// @dev See {ICube3Module}
abstract contract ModuleBase is ICube3Module, ERC165 {
    // TODO: import these
    bytes32 public constant MODULE_CALL_SUCCEEDED = keccak256("MODULE_CALL_SUCCEEDED");
    bytes32 public constant MODULE_CALL_FAILED = keccak256("MODULE_CALL_FAILED");

    // interface wrapping the Cube3RouterProxy for convenience
    ICube3Router internal immutable cube3router;

    /// @inheritdoc	ICube3Module
    string public moduleVersion;
    bytes16 public immutable moduleId;

    // The expected CUBE3 Payload length (in bytes) for this module.
    uint256 public immutable expectedPayloadSize;

    /// @inheritdoc	ICube3Module
    bool public isDeprecated;

    /*//////////////////////////////////////////////////////////////
            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev During construction, the module makes a call to the router to ensure the version supplied has
    ///      not already been installed.
    /// @dev The `version` string should be validated for correctness prior to deployment.
    /// @param cubeRouterProxy Contract address of the Cube3Router proxy.
    /// @param version Human-readable module version, where minimum valid length is 9 bytes and max valid length is 32 bytes: `xxx-x.x.x`
    constructor(address cubeRouterProxy, string memory version, uint256 payloadSize) {
        require(cubeRouterProxy != address(0), "CM03: invalid proxy");
        require(bytes(version).length >= 9 && bytes(version).length <= 32, "CM04: invalid version");
        require(_isValidVersionSchema(version), "CM05: invalid schema");
        require(payloadSize > 0, "TODO: invalid payload size");

        moduleVersion = version;
        moduleId = bytes16(keccak256(abi.encode(moduleVersion)));
        expectedPayloadSize = payloadSize;

        cube3router = ICube3Router(cubeRouterProxy);

        // check for an existing version so we don't deploy two of the same version
        require(cube3router.getModuleAddressById(moduleId) == address(0), "CM01: version already registered");

        emit ModuleDeployed(cubeRouterProxy, moduleId, version);
    }

    /*//////////////////////////////////////////////////////////////
            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Restricts function calls to the address of the Router Proxy
    modifier onlyCube3Router() {
        require(msg.sender == address(cube3router), "CM02: only router");
        _;
    }

    /*//////////////////////////////////////////////////////////////
            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc	ICube3Module
    function deprecate() external onlyCube3Router returns (bool, string memory) {
        isDeprecated = true;
        string memory version = moduleVersion; // gas-saving
        emit ModuleDeprecated(moduleId, version);
        return (true, version);
    }

    /*//////////////////////////////////////////////////////////////
            ERC165
    //////////////////////////////////////////////////////////////*/
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ICube3Module).interfaceId || super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
            VERSION UTILS
    //////////////////////////////////////////////////////////////*/

    /// @dev Module installation is infrequent and performed by CUBE3, so the slightly elevated gas cost
    ///      of this check is acceptable given the operational significance.
    /// @dev Is NOT a comprehensive validation. Validation on the schema should be done prior to deployment.
    /// @dev A minimal check evaluating that the version string conforms to the schema: {xxx-x.x.x}
    /// @dev Checks for the correct version schema by counting the "." separating MAJOR.MINOR.PATCH
    /// @dev Checks for the presence of the single "-" separating name and version number
    function _isValidVersionSchema(string memory version_) internal pure returns (bool) {
        uint256 versionSeparatorCount;
        uint256 dashCount;

        bytes memory b = bytes(version_);
        uint256 len = b.length;

        for (uint256 i; i < len;) {
            bytes1 char = b[i];
            if (char == ".") {
                versionSeparatorCount++;
            } else if (char == "-") {
                dashCount++;
            }
            unchecked {
                ++i;
            }
        }
        if (versionSeparatorCount != 2 || dashCount != 1) {
            return false;
        }
        return true;
    }
}
