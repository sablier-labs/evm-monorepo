// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

import { IFlowNFTDescriptor } from "./interfaces/IFlowNFTDescriptor.sol";

/// @title FlowNFTDescriptor
/// @notice See the documentation in {IFlowNFTDescriptor}.
contract FlowNFTDescriptor is IFlowNFTDescriptor {
    /// @inheritdoc IFlowNFTDescriptor
    function tokenURI(
        IERC721Metadata, /* sablierFlow */
        uint256 /* streamId */
    )
        external
        pure
        override
        returns (string memory uri)
    {
        // solhint-disable max-line-length,quotes
        string memory svg =
            '<svg width="500" height="500" style="background-color: #14161F;" xmlns="http://www.w3.org/2000/svg" viewBox="20 -400 200 1000"><path id="Logo" fill="#fff" fill-opacity="1" d="m133.559,124.034c-.013,2.412-1.059,4.848-2.923,6.402-2.558,1.819-5.168,3.439-7.888,4.996-14.44,8.262-31.047,12.565-47.674,12.569-8.858.036-17.838-1.272-26.328-3.663-9.806-2.766-19.087-7.113-27.562-12.778-13.842-8.025,9.468-28.606,16.153-35.265h0c2.035-1.838,4.252-3.546,6.463-5.224h0c6.429-5.655,16.218-2.835,20.358,4.17,4.143,5.057,8.816,9.649,13.92,13.734h.037c5.736,6.461,15.357-2.253,9.38-8.48,0,0-3.515-3.515-3.515-3.515-11.49-11.478-52.656-52.664-64.837-64.837l.049-.037c-1.725-1.606-2.719-3.847-2.751-6.204h0c-.046-2.375,1.062-4.582,2.726-6.229h0l.185-.148h0c.099-.062,.222-.148,.37-.259h0c2.06-1.362,3.951-2.621,6.044-3.842C57.763-3.473,97.76-2.341,128.637,18.332c16.671,9.946-26.344,54.813-38.651,40.199-6.299-6.096-18.063-17.743-19.668-18.811-6.016-4.047-13.061,4.776-7.752,9.751l68.254,68.371c1.724,1.601,2.714,3.84,2.738,6.192Z" transform="scale(1.5, 1.5)" /></svg>';

        string memory json = string.concat(
            '{"description": "This NFT represents a payment stream in Sablier Flow",',
            '"external_url": "https://sablier.com",',
            '"name": "Sablier Flow",',
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(svg)),
            '"}'
        );

        uri = string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }
}
