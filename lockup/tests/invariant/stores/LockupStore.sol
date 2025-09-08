// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/Lockup.sol";
import { StreamAction } from "tests/utils/Types.sol";

/// @dev Storage variables needed by all lockup handlers.
contract LockupStore {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public lastStreamId;
    uint256[] public streamIds;

    mapping(uint256 streamId => mapping(StreamAction action => uint256 gas)) public gasUsed;
    mapping(uint256 streamId => bool recorded) public isPreviousStatusRecorded;
    mapping(uint256 streamId => Lockup.Status status) public previousStatusOf;
    mapping(uint256 streamId => address recipient) public recipients;
    mapping(uint256 streamId => address sender) public senders;

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function pushStreamId(uint256 streamId, address sender, address recipient) external {
        // Store the stream IDs, the senders, and the recipients.
        streamIds.push(streamId);
        senders[streamId] = sender;
        recipients[streamId] = recipient;

        // Update the last stream ID.
        lastStreamId = streamId;
    }

    /// @dev Records gas used by an action.
    function recordGasUsage(uint256 streamId, StreamAction action, uint256 gas) external {
        // We want to store the maximum gas used by any action.
        if (gas > gasUsed[streamId][action]) {
            gasUsed[streamId][action] = gas;
        }
    }

    function updateIsPreviousStatusRecorded(uint256 streamId) external {
        isPreviousStatusRecorded[streamId] = true;
    }

    function updatePreviousStatusOf(uint256 streamId, Lockup.Status status) external {
        previousStatusOf[streamId] = status;
    }

    function updateRecipient(uint256 streamId, address newRecipient) external {
        recipients[streamId] = newRecipient;
    }
}
