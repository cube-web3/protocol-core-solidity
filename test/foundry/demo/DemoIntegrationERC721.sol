// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/src/token/ERC721/ERC721.sol";
import "@openzeppelin/src/access/Ownable.sol";

import {Cube3ProtectionImmutable} from "../../../src/Cube3Protection.sol";

contract DemoIntegrationERC721 is ERC721, Cube3ProtectionImmutable {
    uint256 private _tokenIdCounter;

    mapping(address => uint256) mintsPerAddress;

    uint256 constant MAX_MINT = 3;

    constructor(address cubeRouter)
        ERC721("Cube3ProtectedNFT", "CP3NFT")
        Cube3ProtectionImmutable(cubeRouter, msg.sender)
    {}

    function safeMint(uint256 qty, bytes calldata cube3SecurePayload) public cube3Protected(cube3SecurePayload) {
        require(mintsPerAddress[msg.sender] + qty <= MAX_MINT, "Max mint per address reached");
        uint256 tokenId;
        for (uint256 i; i < qty;) {
            tokenId = ++_tokenIdCounter;
            mintsPerAddress[msg.sender] += qty;
            _safeMint(msg.sender, tokenId);
            unchecked {
                ++i;
            }
        }
    }

    // both ERC721 and Cube3Integration implement this function, so we need to override it and call super.supportsInterface
    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
