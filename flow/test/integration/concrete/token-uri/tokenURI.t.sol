// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC721Errors } from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract TokenURI_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_NFTDoesNotExist() external {
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, nullStreamId));
        flow.tokenURI({ streamId: nullStreamId });
    }

    function test_GivenNFTExists() external view {
        // It should return the correct token URI
        string memory actualURI = flow.tokenURI({ streamId: defaultStreamId });
        string memory expectedURI = "";
        assertEq(actualURI, expectedURI, "tokenURI");
    }
}
