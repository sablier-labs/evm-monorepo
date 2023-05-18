// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract TokenURI_Integration_Basic_Test is Integration_Test, Lockup_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_NFTDoesNotExist() external {
        uint256 nullStreamId = 1729;
        vm.expectRevert("ERC721: invalid token ID");
        lockup.tokenURI({ tokenId: nullStreamId });
    }

    modifier whenNFTExists() {
        _;
    }

    function test_TokenURI() external whenNFTExists {
        uint256 streamId = createDefaultStream();
        string memory actualTokenURI = lockup.tokenURI({ tokenId: streamId });
        string memory expectedTokenURI = string.concat("This is the NFT descriptor for ", lockup.symbol());
        assertEq(actualTokenURI, expectedTokenURI, "tokenURI");
    }
}
