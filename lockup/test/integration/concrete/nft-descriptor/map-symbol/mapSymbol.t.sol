// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { Errors } from "src/libraries/Errors.sol";

import { NFTDescriptor_Integration_Concrete_Test } from "../NFTDescriptor.t.sol";

contract MapSymbol_Integration_Concrete_Test is NFTDescriptor_Integration_Concrete_Test {
    function test_RevertWhen_UnknownNFT() external {
        ERC721 nft = new ERC721("Foo NFT", "FOO");
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2NFTDescriptor_UnknownNFT.selector, nft, "FOO"));
        nftDescriptorMock.mapSymbol_(nft);
    }

    modifier whenKnownNFT() {
        _;
    }

    function test_MapSymbol_LockupDynamic() external {
        string memory actualStreamingModel = nftDescriptorMock.mapSymbol_(lockupDynamic);
        string memory expectedStreamingModel = "Lockup Dynamic";
        assertEq(actualStreamingModel, expectedStreamingModel, "streamingModel");
    }

    function test_MapSymbol_LockupLinear() external {
        string memory actualStreamingModel = nftDescriptorMock.mapSymbol_(lockupLinear);
        string memory expectedStreamingModel = "Lockup Linear";
        assertEq(actualStreamingModel, expectedStreamingModel, "streamingModel");
    }
}
