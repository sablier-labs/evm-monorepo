// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import { ISablierFlowNFTDescriptor } from "./interfaces/ISablierFlowNFTDescriptor.sol";

/// @title ISablierFlowNFTDescriptor
/// @notice See the documentation in {ISablierFlowNFTDescriptor}.
contract SablierFlowNFTDescriptor is ISablierFlowNFTDescriptor {
    /// @dev Currently it returns an empty string. In the future, it will return an NFT SVG.
    function tokenURI(
        IERC721Metadata, /* sablierFlow */
        uint256 /* streamId */
    )
        external
        pure
        override
        returns (string memory uri)
    {
        return "";
    }
}
