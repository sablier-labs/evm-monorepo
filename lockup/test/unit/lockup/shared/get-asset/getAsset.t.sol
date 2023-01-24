// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Shared_Test } from "../SharedTest.t.sol";

abstract contract GetAsset_Test is Shared_Test {
    /// @dev it should return the zero address.
    function test_GetAsset_StreamNull() external {
        uint256 nullStreamId = 1729;
        IERC20 actualAsset = lockup.getAsset(nullStreamId);
        IERC20 expectedAsset = IERC20(address(0));
        assertEq(actualAsset, expectedAsset);
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct address of the ERC-20 asset.
    function test_GetAsset() external streamNonNull {
        uint256 streamId = createDefaultStream();
        IERC20 actualAsset = lockup.getAsset(streamId);
        IERC20 expectedAsset = dai;
        assertEq(actualAsset, expectedAsset);
    }
}
