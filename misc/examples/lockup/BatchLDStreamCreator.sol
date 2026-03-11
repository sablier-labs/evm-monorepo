// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ISablierBatchLockup } from "@sablier/lockup/src/interfaces/ISablierBatchLockup.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { BatchLockup } from "@sablier/lockup/src/types/BatchLockup.sol";
import { LockupDynamic } from "@sablier/lockup/src/types/LockupDynamic.sol";

contract BatchLDStreamCreator {
    // Mainnet addresses
    IERC20 public constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    // See https://docs.sablier.com/guides/lockup/deployments for all deployments
    ISablierLockup public constant LOCKUP = ISablierLockup(0xcF8ce57fa442ba50aCbC57147a62aD03873FfA73);
    ISablierBatchLockup public constant BATCH_LOCKUP = ISablierBatchLockup(0x0636D83B184D65C242c43de6AAd10535BFb9D45a);

    /// @dev For this function to work, the sender must have approved this dummy contract to spend DAI.
    function batchCreateStreams(uint128 perStreamAmount) public returns (uint256[] memory streamIds) {
        // Create a batch of two streams
        uint256 batchSize = 2;

        // Calculate the combined amount of DAI tokens to transfer to this contract
        uint256 transferAmount = perStreamAmount * batchSize;

        // Transfer the provided amount of DAI tokens to this contract
        DAI.transferFrom(msg.sender, address(this), transferAmount);

        // Approve the Batch contract to spend DAI
        DAI.approve({ spender: address(BATCH_LOCKUP), value: transferAmount });

        // Declare the first stream in the batch
        BatchLockup.CreateWithTimestampsLD memory stream0;
        stream0.sender = address(0xABCD); // The sender to stream the tokens, he will be able to cancel the stream
        stream0.recipient = address(0xCAFE); // The recipient of the streamed tokens
        stream0.depositAmount = perStreamAmount; // The deposit amount of each stream, inclusive of all fees
        stream0.cancelable = true; // Whether the stream will be cancelable or not
        stream0.transferable = false; // Whether the recipient can transfer the NFT or not
        stream0.startTime = uint40(block.timestamp); // The start time of the stream

        // Declare some dummy segments
        stream0.segments = new LockupDynamic.Segment[](2);
        stream0.segments[0] = LockupDynamic.Segment({
            amount: uint128(perStreamAmount / 2),
            exponent: ud2x18(0.25e18),
            timestamp: uint40(block.timestamp + 1 weeks)
        });
        stream0.segments[1] = (
            LockupDynamic.Segment({
                amount: uint128(perStreamAmount - stream0.segments[0].amount),
                exponent: ud2x18(2.71e18),
                timestamp: uint40(block.timestamp + 24 weeks)
            })
        );

        // Declare the second stream in the batch
        BatchLockup.CreateWithTimestampsLD memory stream1;
        stream1.sender = address(0xABCD); // The sender to stream the tokens, he will be able to cancel the stream
        stream1.recipient = address(0xBEEF); // The recipient of the streamed tokens
        stream1.depositAmount = perStreamAmount; // The deposit amount of each stream
        stream1.cancelable = false; // Whether the stream will be cancelable or not
        stream1.transferable = false; // Whether the recipient can transfer the NFT or not
        stream1.startTime = uint40(block.timestamp); // The start time of the stream

        // Declare some dummy segments
        stream1.segments = new LockupDynamic.Segment[](2);
        stream1.segments[0] = LockupDynamic.Segment({
            amount: uint128(perStreamAmount / 4),
            exponent: ud2x18(1e18),
            timestamp: uint40(block.timestamp + 4 weeks)
        });
        stream1.segments[1] = (
            LockupDynamic.Segment({
                amount: uint128(perStreamAmount - stream1.segments[0].amount),
                exponent: ud2x18(3.14e18),
                timestamp: uint40(block.timestamp + 52 weeks)
            })
        );

        // Fill the batch array
        BatchLockup.CreateWithTimestampsLD[] memory batch = new BatchLockup.CreateWithTimestampsLD[](batchSize);
        batch[0] = stream0;
        batch[1] = stream1;

        streamIds = BATCH_LOCKUP.createWithTimestampsLD(LOCKUP, DAI, batch);
    }
}
