// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { MockERC721 } from "forge-std/src/mocks/MockERC721.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "test/Base.t.sol";

contract MapSymbol_Integration_Concrete_Test is Base_Test {
    function test_RevertGiven_UnknownNFTContract() external {
        MockERC721 nft = new MockERC721();
        nft.initialize("Foo", "FOO");
        vm.expectRevert(abi.encodeWithSelector(Errors.LockupNFTDescriptor_UnknownNFT.selector, nft, "FOO"));
        nftDescriptorMock.mapSymbol_(IERC721Metadata(address(nft)));
    }

    function test_GivenKnownNFTContract() external view {
        string memory actualLockupModel = nftDescriptorMock.mapSymbol_(lockup);
        string memory expectedLockupModel = "Sablier Lockup";
        assertEq(actualLockupModel, expectedLockupModel, "lockupModel");
    }
}
