// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

/// @dev Storage variables needed for handlers.
contract FlowStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public lastStreamId;
    mapping(uint256 streamId => address recipient) public recipients;
    mapping(uint256 streamId => address sender) public senders;
    mapping(uint256 streamId => uint128 depositedAmount) public depositedAmounts;
    mapping(uint256 streamId => uint128 refundedAmount) public refundedAmounts;
    mapping(uint256 streamId => uint128 withdrawnAmount) public withdrawnAmounts;
    uint256[] public streamIds;
    uint256 public streamDepositedAmountsSum;
    uint256 public streamRefundedAmountsSum;
    uint256 public streamWithdrawnAmountsSum;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function pushStreamId(uint256 streamId, address sender, address recipient) external {
        // Store the stream ids, the senders, and the recipients.
        streamIds.push(streamId);
        senders[streamId] = sender;
        recipients[streamId] = recipient;

        // Update the last stream id.
        lastStreamId = streamId;
    }

    function updateStreamDepositedAmountsSum(uint256 streamId, uint128 amount) external {
        depositedAmounts[streamId] += amount;
        streamDepositedAmountsSum += amount;
    }

    function updateStreamRefundedAmountsSum(uint256 streamId, uint128 amount) external {
        refundedAmounts[streamId] += amount;
        streamRefundedAmountsSum += amount;
    }

    function updateStreamWithdrawnAmountsSum(uint256 streamId, uint128 amount) external {
        withdrawnAmounts[streamId] += amount;
        streamWithdrawnAmountsSum += amount;
    }
}
