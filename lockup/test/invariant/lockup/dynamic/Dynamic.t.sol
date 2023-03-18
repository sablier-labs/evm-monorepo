// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";
import { SablierV2LockupDynamic } from "src/SablierV2LockupDynamic.sol";
import { Lockup, LockupDynamic } from "src/types/DataTypes.sol";

import { Lockup_Invariant_Test } from "../Lockup.t.sol";
import { FlashLoanHandler } from "../../handlers/FlashLoanHandler.t.sol";
import { LockupDynamicCreateHandler } from "../../handlers/LockupDynamicCreateHandler.t.sol";
import { LockupDynamicHandler } from "../../handlers/LockupDynamicHandler.t.sol";

/// @title Dynamic_Invariant_Test
/// @dev Invariant tests for for {SablierV2LockupDynamic}.
contract Dynamic_Invariant_Test is Lockup_Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupDynamicHandler internal dynamicHandler;
    LockupDynamicCreateHandler internal dynamicCreateHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Invariant_Test.setUp();

        // Deploy the dynamic contract handlers.
        dynamicHandler = new LockupDynamicHandler({
            asset_: DEFAULT_ASSET,
            dynamic_: dynamic,
            store_: lockupHandlerStorage
        });
        dynamicCreateHandler = new LockupDynamicCreateHandler({
            asset_: DEFAULT_ASSET,
            comptroller_: comptroller,
            dynamic_: dynamic,
            store_: lockupHandlerStorage
        });

        // Cast the dynamic contract as {SablierV2Lockup} and the dynamic handler as {LockupHandler}.
        lockup = dynamic;
        lockupHandler = dynamicHandler;

        // Deploy the flash loan handler by casting the dynamic contract as {SablierV2FlashLoan}.
        flashLoanHandler = new FlashLoanHandler({
            asset_: DEFAULT_ASSET,
            comptroller_: comptroller,
            flashLoanContract_: SablierV2FlashLoan(address(dynamic)),
            receiver_: goodFlashLoanReceiver
        });

        // Target the flash loan handler and the dynamic handlers for invariant testing.
        targetContract(address(flashLoanHandler));
        targetContract(address(dynamicHandler));
        targetContract(address(dynamicCreateHandler));

        // Exclude the dynamic handlers from being the `msg.sender`.
        excludeSender(address(flashLoanHandler));
        excludeSender(address(dynamicHandler));
        excludeSender(address(dynamicCreateHandler));

        // Label the dynamic handler.
        vm.label({ account: address(dynamicHandler), newLabel: "LockupDynamicHandler" });
        vm.label({ account: address(dynamicCreateHandler), newLabel: "LockupDynamicCreateHandler" });
        vm.label({ account: address(flashLoanHandler), newLabel: "FlashLoanHandler" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    // solhint-disable max-line-length
    function invariant_NullStatus() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupDynamic.Stream memory actualStream = dynamic.getStream(streamId);
            address actualRecipient = lockup.getRecipient(streamId);

            // If the stream is null, it should contain only zero values.
            if (lockup.getStatus(streamId) == Lockup.Status.NULL) {
                assertEq(actualStream.amounts.deposit, 0, "Invariant violated: stream null, deposit amount not zero");
                assertEq(
                    actualStream.amounts.withdrawn, 0, "Invariant violated: stream null, withdrawn amount not zero"
                );
                assertEq(
                    address(actualStream.asset),
                    address(0),
                    "Invariant violated: stream null, asset not zero address"
                );
                assertEq(actualStream.endTime, 0, "Invariant violated: stream null, end time not zero");
                assertEq(actualStream.isCancelable, false, "Invariant violated: stream null, isCancelable not false");
                assertEq(actualStream.segments.length, 0, "Invariant violated: stream null, segment count not zero");
                assertEq(actualStream.sender, address(0), "Invariant violated: stream null, sender not zero address");
                assertEq(actualStream.startTime, 0, "Invariant violated: stream null, start time not zero");
                assertEq(actualRecipient, address(0), "Invariant violated: stream null, recipient not zero address");
            }
            // If the stream is not null, it should contain a non-zero deposit amount.
            else {
                assertNotEq(
                    actualStream.amounts.deposit, 0, "Invariant violated: stream non-null, deposit amount zero"
                );
                assertNotEq(actualStream.endTime, 0, "Invariant violated: stream non-null, end time zero");
            }
        }
    }

    function invariant_SegmentMilestonesOrdered() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);

            // If the stream is null, it doesn't have segments.
            if (dynamic.getStatus(streamId) == Lockup.Status.NULL) {
                continue;
            }

            LockupDynamic.Segment[] memory segments = dynamic.getSegments(streamId);
            uint40 previousMilestone = segments[0].milestone;
            for (uint256 j = 1; j < segments.length; ++j) {
                assertGt(
                    segments[j].milestone, previousMilestone, "Invariant violated: segment milestones not ordered"
                );
                previousMilestone = segments[j].milestone;
            }
        }
    }
}
