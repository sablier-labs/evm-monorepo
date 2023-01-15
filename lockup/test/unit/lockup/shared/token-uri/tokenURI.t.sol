// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { Shared_Test } from "../SharedTest.t.sol";

abstract contract TokenURI_Test is Shared_Test {
    /// @dev it should return an empty string.
    function test_TokenURI_StreamNull() external {
        uint256 nullStreamId = 1729;
        string memory actualTokenURI = lockup.tokenURI({ tokenId: nullStreamId });
        string memory expectedTokenURI = string("");
        assertEq(actualTokenURI, expectedTokenURI);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return an empty string.
    function test_TokenURI() external {
        uint256 streamId = createDefaultStream();
        string memory actualTokenURI = lockup.tokenURI({ tokenId: streamId });
        string memory expectedTokenURI = string("");
        assertEq(actualTokenURI, expectedTokenURI);
    }
}
