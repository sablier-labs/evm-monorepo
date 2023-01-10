// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract GetERC20Token__Test is SharedTest {
    /// @dev it should return the zero address.
    function testGetERC20Token__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        IERC20 actualToken = sablierV2.getERC20Token(nonStreamId);
        IERC20 expectedToken = IERC20(address(0));
        assertEq(actualToken, expectedToken);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return the correct ERC-20 token.
    function testGetERC20Token() external StreamExistent {
        uint256 streamId = createDefaultStream();
        IERC20 actualToken = sablierV2.getERC20Token(streamId);
        IERC20 expectedToken = dai;
        assertEq(actualToken, expectedToken);
    }
}
