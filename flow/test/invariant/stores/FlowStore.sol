// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Storage variables needed for handlers.
contract FlowStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public lastStreamId;
    uint256[] public streamIds;

    mapping(uint256 streamId => uint128 depositedAmount) public depositedAmounts;
    mapping(uint256 streamId => uint128 refundedAmount) public refundedAmounts;
    mapping(uint256 streamId => uint128 withdrawnAmount) public withdrawnAmounts;
    mapping(IERC20 token => uint256 sum) public depositedAmountsSum;
    mapping(IERC20 token => uint256 sum) public refundedAmountsSum;
    mapping(IERC20 token => uint256 sum) public withdrawnAmountsSum;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function pushStreamId(uint256 streamId) external {
        // Store the stream ids, the senders, and the recipients.
        streamIds.push(streamId);

        // Update the last stream id.
        lastStreamId = streamId;
    }

    function updateStreamDepositedAmountsSum(uint256 streamId, IERC20 token, uint128 amount) external {
        depositedAmounts[streamId] += amount;
        depositedAmountsSum[token] += amount;
    }

    function updateStreamRefundedAmountsSum(uint256 streamId, IERC20 token, uint128 amount) external {
        refundedAmounts[streamId] += amount;
        refundedAmountsSum[token] += amount;
    }

    function updateStreamWithdrawnAmountsSum(uint256 streamId, IERC20 token, uint128 amount) external {
        withdrawnAmounts[streamId] += amount;
        withdrawnAmountsSum[token] += amount;
    }
}
