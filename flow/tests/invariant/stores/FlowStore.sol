// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Flow } from "src/types/DataTypes.sol";

/// @dev Storage variables needed for handlers.
contract FlowStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20[] public tokens;

    // Stream IDs
    uint256 public lastStreamId;
    uint256[] public streamIds;

    // Amounts
    mapping(uint256 streamId => uint128 amount) public totalDepositsByStream;
    mapping(uint256 streamId => uint128 amount) public totalRefundsByStream;
    mapping(uint256 streamId => uint128 amount) public totalWithdrawalsByStream;
    mapping(IERC20 token => uint256 amount) public totalDepositsByToken;
    mapping(IERC20 token => uint256 amount) public totalRefundsByToken;
    mapping(IERC20 token => uint256 amount) public totalWithdrawalsByToken;

    // Previous values
    mapping(uint256 streamId => Flow.Status status) public previousStatusOf;
    mapping(uint256 streamId => uint40 snapshotTime) public previousSnapshotTime;
    mapping(uint256 streamId => uint256 amount) public previousTotalDebtOf;
    mapping(uint256 streamId => uint256 amount) public previousUncoveredDebtOf;

    /// @dev This struct represents a time period during which rate per second remains constant.
    /// @param funcName The name of the function updating the struct.
    /// @param ratePerSecond The rate per second for this period.
    /// @param start The start time of the period.
    /// @param end The end time of the period.
    struct Period {
        string funcName;
        uint128 ratePerSecond;
        uint40 start;
        uint40 end;
    }

    /// @dev Each stream is mapped to an array of periods. This is used to calculate the total streamed amount.
    mapping(uint256 streamId => Period[] period) public periods;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20[] memory tokens_) {
        for (uint256 i = 0; i < tokens_.length; ++i) {
            tokens.push(tokens_[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function getPeriod(uint256 streamId, uint256 index) public view returns (Period memory) {
        return periods[streamId][index];
    }

    function getPeriods(uint256 streamId) public view returns (Period[] memory) {
        return periods[streamId];
    }

    function getTokens() public view returns (IERC20[] memory) {
        return tokens;
    }

    function initStreamId(uint256 streamId, uint128 ratePerSecond, uint40 startTime, uint40 blockTimestamp) external {
        // Store the stream id and the period during which provided ratePerSecond applies.
        streamIds.push(streamId);
        periods[streamId].push(
            Period({
                funcName: "create",
                ratePerSecond: ratePerSecond,
                start: startTime == 0 ? blockTimestamp : startTime,
                end: 0
            })
        );

        // Update the last stream id.
        lastStreamId = streamId;
    }

    function pushPeriod(
        string memory typeOfPeriod,
        uint256 streamId,
        uint128 newRatePerSecond,
        uint40 blockTimestamp
    )
        external
    {
        uint256 count = periods[streamId].length - 1;

        // If the previous start time is in the future keep the same periods.
        if (periods[streamId][count].start >= blockTimestamp) {
            return;
        }

        // Update the end time of the previous period.
        periods[streamId][count].end = blockTimestamp;

        // Push the new period with the provided rate per second.
        periods[streamId].push(
            Period({ funcName: typeOfPeriod, ratePerSecond: newRatePerSecond, start: blockTimestamp, end: 0 })
        );
    }

    function updatePreviousValues(
        uint256 streamId,
        uint40 snapshotTime,
        Flow.Status status,
        uint256 totalDebtOf,
        uint256 uncoveredDebtOf
    )
        external
    {
        previousSnapshotTime[streamId] = snapshotTime;
        previousStatusOf[streamId] = status;
        previousTotalDebtOf[streamId] = totalDebtOf;
        previousUncoveredDebtOf[streamId] = uncoveredDebtOf;
    }

    function updateTotalDeposits(uint256 streamId, IERC20 token, uint128 amount) external {
        totalDepositsByStream[streamId] += amount;
        totalDepositsByToken[token] += amount;
    }

    function updateTotalRefunds(uint256 streamId, IERC20 token, uint128 amount) external {
        totalRefundsByStream[streamId] += amount;
        totalRefundsByToken[token] += amount;
    }

    function updateTotalWithdrawals(uint256 streamId, IERC20 token, uint128 amount) external {
        totalWithdrawalsByStream[streamId] += amount;
        totalWithdrawalsByToken[token] += amount;
    }
}
