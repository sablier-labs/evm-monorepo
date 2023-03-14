// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { IERC721Metadata } from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";

/// @title ISablierV2NFTDescriptor
/// @notice This contract produces the URI describing the Sablier stream NFTs.
interface ISablierV2NFTDescriptor {
    /// @notice Produces the URI describing a particular stream NFT.
    /// @dev This is a data URI with the JSON contents directly inlined.
    /// @param sablierContract The address of the Sablier contract the stream belongs to.
    /// @param streamId The id of the stream for which to produce a description.
    /// @return uri The URI of the ERC721-compliant metadata.
    function tokenURI(IERC721Metadata sablierContract, uint256 streamId) external view returns (string memory uri);
}
