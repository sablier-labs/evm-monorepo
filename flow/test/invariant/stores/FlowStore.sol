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

    mapping(uint256 streamId => uint128 amount) public depositedAmounts;
    mapping(uint256 streamId => uint128 amount) public refundedAmounts;
    mapping(uint256 streamId => uint128 amount) public withdrawnAmounts;
    mapping(IERC20 token => uint256 amount) public depositedAmountsSum;
    mapping(IERC20 token => uint256 amount) public refundedAmountsSum;
    mapping(IERC20 token => uint256 amount) public withdrawnAmountsSum;

    /// @dev This struct represents a time period during which rate per second remains constant.
    /// @param ratePerSecond The rate per second for this period.
    /// @param start The start time of the period.
    /// @param end The end time of the period.
    struct Period {
        uint128 ratePerSecond;
        uint40 start;
        uint40 end;
    }

    /// @dev Each stream is mapped to an array of periods. This is used to calculate the total streamed amount.
    mapping(uint256 streamId => Period[] period) public periods;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function getPeriod(uint256 streamId, uint256 index) public view returns (Period memory) {
        return periods[streamId][index];
    }

    function getPeriods(uint256 streamId) public view returns (Period[] memory) {
        return periods[streamId];
    }

    function initStreamId(uint256 streamId, uint128 ratePerSecond) external {
        // Store the stream id and the period during which provided ratePerSecond applies.
        streamIds.push(streamId);
        periods[streamId].push(Period({ ratePerSecond: ratePerSecond, start: uint40(block.timestamp), end: 0 }));

        // Update the last stream id.
        lastStreamId = streamId;
    }

    function updatePeriods(uint256 streamId, uint128 ratePerSecond) external {
        // Update the end time of the previous period.
        periods[streamId][periods[streamId].length - 1].end = uint40(block.timestamp);

        // Push the new period with the provided rate per second.
        periods[streamId].push(Period({ ratePerSecond: ratePerSecond, start: uint40(block.timestamp), end: 0 }));
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
