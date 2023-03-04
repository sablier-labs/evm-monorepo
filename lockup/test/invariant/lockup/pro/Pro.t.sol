// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";
import { Lockup, LockupPro } from "src/types/DataTypes.sol";

import { Lockup_Invariant_Test } from "../Lockup.t.sol";
import { FlashLoanHandler } from "../../handlers/FlashLoanHandler.t.sol";
import { LockupProHandler } from "../../handlers/LockupProHandler.t.sol";
import { LockupProCreateHandler } from "../../handlers/LockupProCreateHandler.t.sol";

/// @title Pro_Invariant_Test
/// @dev Invariants for the {SablierV2LockupPro} contract.
contract Pro_Invariant_Test is Lockup_Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                PUBLIC TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupProHandler internal proHandler;
    LockupProCreateHandler internal proCreateHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Invariant_Test.setUp();

        // Deploy the pro contract handlers.
        proHandler = new LockupProHandler({ asset_: DEFAULT_ASSET, pro_: pro, store_: lockupHandlerStorage });
        proCreateHandler = new LockupProCreateHandler({
            asset_: DEFAULT_ASSET,
            comptroller_: comptroller,
            pro_: pro,
            store_: lockupHandlerStorage
        });

        // Cast the pro contract as {SablierV2Lockup} and the pro handler as {LockupHandler}.
        lockup = pro;
        lockupHandler = proHandler;

        // Deploy the flash loan handler by casting the pro contract as {SablierV2FlashLoan}.
        flashLoanHandler = new FlashLoanHandler({
            asset_: DEFAULT_ASSET,
            comptroller_: comptroller,
            flashLoanContract_: SablierV2FlashLoan(address(pro)),
            receiver_: goodFlashLoanReceiver
        });

        // Target the flash loan handler and the pro handlers for invariant testing.
        targetContract(address(flashLoanHandler));
        targetContract(address(proHandler));
        targetContract(address(proCreateHandler));

        // Exclude the pro handlers from being the `msg.sender`.
        excludeSender(address(flashLoanHandler));
        excludeSender(address(proHandler));
        excludeSender(address(proCreateHandler));

        // Label the pro handler.
        vm.label({ account: address(proHandler), newLabel: "LockupProHandler" });
        vm.label({ account: address(proCreateHandler), newLabel: "LockupProCreateHandler" });
        vm.label({ account: address(flashLoanHandler), newLabel: "FlashLoanHandler" });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    // prettier-ignore
    // solhint-disable max-line-length
    function invariant_NullStatus() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            LockupPro.Stream memory actualStream = pro.getStream(streamId);
            address actualRecipient = lockup.getRecipient(streamId);

            // If the stream is null, it should contain only zero values.
            if (lockup.getStatus(streamId) == Lockup.Status.NULL) {
                assertEq(actualStream.amounts.deposit, 0, "Invariant violated: stream null, deposit amount not zero");
                assertEq(actualStream.amounts.withdrawn, 0, "Invariant violated: stream null, withdrawn amount not zero");
                assertEq(address(actualStream.asset), address(0), "Invariant violated: stream null, asset not zero address");
                assertEq(actualStream.endTime, 0, "Invariant violated: stream null, end time not zero");
                assertEq(actualStream.isCancelable, false, "Invariant violated: stream null, isCancelable not false");
                assertEq(actualStream.segments.length, 0, "Invariant violated: stream null, segment count not zero");
                assertEq(actualStream.sender, address(0), "Invariant violated: stream null, sender not zero address");
                assertEq(actualStream.startTime, 0, "Invariant violated: stream null, start time not zero");
                assertEq(actualRecipient, address(0), "Invariant violated: stream null, recipient not zero address");
            }
            // If the stream is not null, it should contain a non-zero deposit amount.
            else {
                assertNotEq(actualStream.amounts.deposit, 0, "Invariant violated: stream non-null, deposit amount zero");
                assertNotEq(actualStream.endTime, 0, "Invariant violated: stream non-null, end time zero");
            }
        }
    }

    function invariant_SegmentMilestonesOrdered() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);

            // If the stream is null, it doesn't have segments.
            if (pro.getStatus(streamId) == Lockup.Status.NULL) {
                continue;
            }

            LockupPro.Segment[] memory segments = pro.getSegments(streamId);
            uint40 previousMilestone = segments[0].milestone;
            for (uint256 j = 1; j < segments.length; ++j) {
                assertGt(
                    segments[j].milestone,
                    previousMilestone,
                    "Invariant violated: segment milestones not ordered"
                );
                previousMilestone = segments[j].milestone;
            }
        }
    }
}
