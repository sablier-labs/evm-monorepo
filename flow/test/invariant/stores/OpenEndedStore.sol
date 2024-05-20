// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

/// @dev Storage variables needed for handlers.
contract OpenEndedStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public lastStreamId;
    mapping(uint256 streamId => address recipient) public recipients;
    mapping(uint256 streamId => address sender) public senders;
    mapping(uint256 streamId => uint128 remainingAmount) public remainingAmountsSum;
    uint256[] public streamIds;
    uint256 public streamDepositedAmountsSum;
    uint256 public streamExtractedAmountsSum;

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

    function sumRemainingAmount(uint256 streamId, uint128 amount) external {
        remainingAmountsSum[streamId] += amount;
    }

    function subtractRemainingAmount(uint256 streamId, uint128 amount) external {
        remainingAmountsSum[streamId] -= amount;
    }

    function updateStreamDepositedAmountsSum(uint256 amount) external {
        streamDepositedAmountsSum += amount;
    }

    function updateStreamExtractedAmountsSum(uint256 amount) external {
        streamExtractedAmountsSum += amount;
    }
}
