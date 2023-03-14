// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IERC721Metadata } from "@openzeppelin/token/ERC721/extensions/IERC721Metadata.sol";
import { ISablierV2NFTDescriptor } from "./interfaces/ISablierV2NFTDescriptor.sol";

/// @title SablierV2NFTDescriptor
/// @dev This is a dummy NFT descriptor for demonstrational purposes.
contract SablierV2NFTDescriptor is ISablierV2NFTDescriptor {
    function tokenURI(
        IERC721Metadata sablierContract,
        uint256 streamId
    ) external view override returns (string memory uri) {
        streamId;
        string memory symbol = sablierContract.symbol();
        uri = string.concat("This is the NFT descriptor for ", symbol);
    }
}
