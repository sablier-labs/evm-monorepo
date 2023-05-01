// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

/// @title LockupHandlerStorage
/// @dev Storage contract for the lockup handler streams.
contract LockupHandlerStorage {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public lastStreamId;
    mapping(uint256 streamId => address recipient) public recipients;
    mapping(uint256 streamId => address sender) public senders;
    uint256[] public streamIds;

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

    function updateRecipient(uint256 streamId, address newRecipient) external {
        recipients[streamId] = newRecipient;
    }
}
