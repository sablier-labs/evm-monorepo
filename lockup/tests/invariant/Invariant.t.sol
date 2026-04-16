// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { StdInvariant } from "forge-std/src/StdInvariant.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupDynamic } from "src/types/LockupDynamic.sol";
import { LockupTranched } from "src/types/LockupTranched.sol";
import { StreamAction } from "tests/utils/Types.sol";
import { Base_Test } from "../Base.t.sol";
import { LockupComptrollerHandler } from "./handlers/LockupComptrollerHandler.sol";
import { LockupCreateHandler } from "./handlers/LockupCreateHandler.sol";
import { LockupHandler } from "./handlers/LockupHandler.sol";
import { Store } from "./stores/Store.sol";

/// @notice Invariants of {SablierLockup} contract.
contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    LockupComptrollerHandler internal comptrollerHandler;
    LockupCreateHandler internal createHandler;
    LockupHandler internal handler;
    Store internal store;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy and label the store contract.
        store = new Store();
        vm.label({ account: address(store), newLabel: "Store" });

        // Deploy the Lockup handlers.
        comptrollerHandler = new LockupComptrollerHandler({ token_: dai, lockup_: lockup });
        createHandler = new LockupCreateHandler({
            token_: dai,
            store_: store,
            lockup_: lockup,
            oracle_: AggregatorV3Interface(address(oracle))
        });
        handler = new LockupHandler({ token_: dai, store_: store, lockup_: lockup });

        // Label the contracts.
        vm.label({ account: address(createHandler), newLabel: "LockupCreateHandler" });
        vm.label({ account: address(handler), newLabel: "LockupHandler" });

        // Target the LockupDynamic handlers for invariant testing.
        targetContract(address(comptrollerHandler));
        targetContract(address(createHandler));
        targetContract(address(handler));

        // Exclude the store from being fuzzed as `msg.sender`.
        excludeSender(address(createHandler));
        excludeSender(address(handler));
        excludeSender(address(lockup));
        excludeSender(address(store));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 COMMON INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    function invariant_NextStreamId() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = lockup.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream ID not incremented");
        }
    }

    function invariant_Balances() external view {
        uint256 erc20Balance = dai.balanceOf(address(lockup));

        uint256 lastStreamId = store.lastStreamId();
        uint256 totalDeposits;
        uint256 totalRefunds;
        uint256 totalWithdrawals;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            totalDeposits += uint256(lockup.getDepositedAmount(streamId));
            totalRefunds += uint256(lockup.getRefundedAmount(streamId));
            totalWithdrawals += uint256(lockup.getWithdrawnAmount(streamId));
        }

        uint256 totals = totalDeposits - totalRefunds - totalWithdrawals;
        assertEq(
            lockup.aggregateAmount(dai),
            totals,
            unicode"Invariant violation: aggregate amount != Σ deposits - Σ refunds - Σ withdrawals"
        );

        assertGe(
            erc20Balance,
            totals,
            unicode"Invariant violation: ERC-20 balance < Σ deposits - Σ refunds - Σ withdrawals"
        );
    }

    function invariant_DepositedGteStreamed() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            assertGe(
                lockup.getDepositedAmount(streamId),
                lockup.streamedAmountOf(streamId),
                "Invariant violation: deposited amount < streamed amount"
            );
        }
    }

    function invariant_DepositedGteWithdrawable() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            assertGe(
                lockup.getDepositedAmount(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violation: deposited amount < withdrawable amount"
            );
        }
    }

    function invariant_DepositedGteWithdrawn() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            assertGe(
                lockup.getDepositedAmount(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violation: deposited amount < withdrawn amount"
            );
        }
    }

    function invariant_DepositedNotZero() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            uint128 depositAmount = lockup.getDepositedAmount(streamId);
            assertNotEq(depositAmount, 0, "Invariant violation: stream non-null, deposited amount zero");
        }
    }

    function invariant_EndTimeGtStartTime() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            assertGt(
                lockup.getEndTime(streamId),
                lockup.getStartTime(streamId),
                "Invariant violation: end time <= start time"
            );
        }
    }

    function invariant_StartTimeNotZero() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            uint40 startTime = lockup.getStartTime(streamId);
            assertGt(startTime, 0, "Invariant violation: start time zero");
        }
    }

    function invariant_StreamedGteWithdrawable() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            assertGe(
                lockup.streamedAmountOf(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violation: streamed amount < withdrawable amount"
            );
        }
    }

    function invariant_StreamedGteWithdrawn() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            assertGe(
                lockup.streamedAmountOf(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violation: streamed amount < withdrawn amount"
            );
        }
    }

    function invariant_StatusCanceled() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.statusOf(streamId) == Lockup.Status.CANCELED) {
                assertGt(
                    lockup.getRefundedAmount(streamId),
                    0,
                    "Invariant violation: canceled stream with a zero refunded amount"
                );
                assertFalse(lockup.isCancelable(streamId), "Invariant violation: canceled stream is cancelable");
                assertEq(
                    lockup.refundableAmountOf(streamId),
                    0,
                    "Invariant violation: canceled stream with a non-zero refundable amount"
                );
                assertGt(
                    lockup.withdrawableAmountOf(streamId),
                    0,
                    "Invariant violation: canceled stream with a zero withdrawable amount"
                );
            }
        }
    }

    function invariant_StatusDepleted() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.isDepleted(streamId)) {
                assertEq(
                    lockup.getDepositedAmount(streamId) - lockup.getRefundedAmount(streamId),
                    lockup.getWithdrawnAmount(streamId),
                    "Invariant violation: depleted stream with deposited amount - refunded amount != withdrawn amount"
                );
                assertFalse(lockup.isCancelable(streamId), "Invariant violation: depleted stream is cancelable");
                assertEq(
                    lockup.refundableAmountOf(streamId),
                    0,
                    "Invariant violation: depleted stream with a non-zero refundable amount"
                );
                assertEq(
                    lockup.withdrawableAmountOf(streamId),
                    0,
                    "Invariant violation: depleted stream with a non-zero withdrawable amount"
                );
            }
        }
    }

    function invariant_StatusPending() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.statusOf(streamId) == Lockup.Status.PENDING) {
                assertEq(
                    lockup.getRefundedAmount(streamId),
                    0,
                    "Invariant violation: pending stream with a non-zero refunded amount"
                );
                assertEq(
                    lockup.getWithdrawnAmount(streamId),
                    0,
                    "Invariant violation: pending stream with a non-zero withdrawn amount"
                );
                assertEq(
                    lockup.refundableAmountOf(streamId),
                    lockup.getDepositedAmount(streamId),
                    "Invariant violation: pending stream with refundable amount != deposited amount"
                );
                assertEq(
                    lockup.streamedAmountOf(streamId),
                    0,
                    "Invariant violation: pending stream with a non-zero streamed amount"
                );
                assertEq(
                    lockup.withdrawableAmountOf(streamId),
                    0,
                    "Invariant violation: pending stream with a non-zero withdrawable amount"
                );
            }
        }
    }

    function invariant_StatusSettled() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.statusOf(streamId) == Lockup.Status.SETTLED) {
                assertEq(
                    lockup.getRefundedAmount(streamId),
                    0,
                    "Invariant violation: settled stream with a non-zero refunded amount"
                );
                assertFalse(lockup.isCancelable(streamId), "Invariant violation: settled stream is cancelable");
                assertEq(
                    lockup.refundableAmountOf(streamId),
                    0,
                    "Invariant violation: settled stream with a non-zero refundable amount"
                );
                assertEq(
                    lockup.streamedAmountOf(streamId),
                    lockup.getDepositedAmount(streamId),
                    "Invariant violation: settled stream with streamed amount != deposited amount"
                );
            }
        }
    }

    function invariant_StatusStreaming() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.statusOf(streamId) == Lockup.Status.STREAMING) {
                assertEq(
                    lockup.getRefundedAmount(streamId),
                    0,
                    "Invariant violation: streaming stream with a non-zero refunded amount"
                );
                assertLt(
                    lockup.streamedAmountOf(streamId),
                    lockup.getDepositedAmount(streamId),
                    "Invariant violation: streaming stream with streamed amount >= deposited amount"
                );
            }
        }
    }

    /// @dev See diagram at https://docs.sablier.com/concepts/lockup/statuses#diagram
    function invariant_StatusTransitions() external {
        uint256 lastStreamId = store.lastStreamId();
        if (lastStreamId == 0) {
            return;
        }

        for (uint256 i = 0; i < lastStreamId - 1; ++i) {
            uint256 streamId = store.streamIds(i);
            Lockup.Status currentStatus = lockup.statusOf(streamId);

            // If this is the first time the status is checked for this stream, skip the invariant test.
            if (!store.isPreviousStatusRecorded(streamId)) {
                store.updateIsPreviousStatusRecorded(streamId);
                return;
            }

            // It should hold the status transition invariants.
            Lockup.Status previousStatus = store.previousStatusOf(streamId);
            if (previousStatus == Lockup.Status.PENDING) {
                assertNotEq(
                    currentStatus, Lockup.Status.DEPLETED, "Invariant violation: pending stream turned depleted"
                );
            } else if (previousStatus == Lockup.Status.STREAMING) {
                assertNotEq(
                    currentStatus, Lockup.Status.PENDING, "Invariant violation: streaming stream turned pending"
                );
            } else if (previousStatus == Lockup.Status.SETTLED) {
                assertNotEq(currentStatus, Lockup.Status.PENDING, "Invariant violation: settled stream turned pending");
                // Note: For a price-gated stream, it is possible for a SETTLED stream to return to STREAMING if the
                // price goes back below the target price when end time is not reached.
                if (lockup.getLockupModel(streamId) != Lockup.Model.LOCKUP_PRICE_GATED) {
                    assertNotEq(
                        currentStatus, Lockup.Status.STREAMING, "Invariant violation: settled stream turned streaming"
                    );
                }
                assertNotEq(
                    currentStatus, Lockup.Status.CANCELED, "Invariant violation: settled stream turned canceled"
                );
            } else if (previousStatus == Lockup.Status.CANCELED) {
                assertNotEq(currentStatus, Lockup.Status.PENDING, "Invariant violation: canceled stream turned pending");
                assertNotEq(
                    currentStatus, Lockup.Status.STREAMING, "Invariant violation: canceled stream turned streaming"
                );
                assertNotEq(currentStatus, Lockup.Status.SETTLED, "Invariant violation: canceled stream turned settled");
            } else if (previousStatus == Lockup.Status.DEPLETED) {
                assertEq(currentStatus, Lockup.Status.DEPLETED, "Invariant violation: depleted status changed");
            }

            // Set the current status as the previous status.
            store.updatePreviousStatusOf(streamId, currentStatus);
        }
    }

    function invariant_GasUsedCreateGeCancel() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            uint256 createGas = store.gasUsed(streamId, StreamAction.CREATE);
            uint256 cancelGas = store.gasUsed(streamId, StreamAction.CANCEL);

            // If cancel action is called 0 times, skip.
            if (cancelGas == 0) return;

            assertGe(createGas, cancelGas, "Invariant violation: cancel gas > create gas");
        }
    }

    function invariant_GasUsedCreateGeWithdraw() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            uint256 createGas = store.gasUsed(streamId, StreamAction.CREATE);
            uint256 withdrawGas = store.gasUsed(streamId, StreamAction.WITHDRAW);

            // If withdraw action is called 0 times, skip.
            if (withdrawGas == 0) return;

            assertGe(createGas, withdrawGas, "Invariant violation: withdraw gas > create gas");
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                LD MODEL INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Unordered segment timestamps are not allowed.
    function invariant_SegmentTimestampsOrdered() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.getLockupModel(streamId) == Lockup.Model.LOCKUP_DYNAMIC) {
                LockupDynamic.Segment[] memory segments = lockup.getSegments(streamId);
                uint40 previousTimestamp = segments[0].timestamp;
                for (uint256 j = 1; j < segments.length; ++j) {
                    assertGt(
                        segments[j].timestamp, previousTimestamp, "Invariant violation: segment timestamps not ordered"
                    );
                    previousTimestamp = segments[j].timestamp;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                LL MODEL INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev If it is not zero, the cliff time must be strictly greater than the start time.
    function invariant_CliffTimeGtStartTimeOrZero() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.getLockupModel(streamId) == Lockup.Model.LOCKUP_LINEAR) {
                if (lockup.getCliffTime(streamId) > 0) {
                    assertGt(
                        lockup.getCliffTime(streamId),
                        lockup.getStartTime(streamId),
                        "Invariant violation: cliff time <= start time"
                    );
                }
            }
        }
    }

    /// @dev The end time must not be less than or equal to the cliff time.
    function invariant_EndTimeGtCliffTime() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.getLockupModel(streamId) == Lockup.Model.LOCKUP_LINEAR) {
                assertGt(
                    lockup.getEndTime(streamId),
                    lockup.getCliffTime(streamId),
                    "Invariant violation: end time <= cliff time"
                );
            }
        }
    }

    /// @dev The streamed amount should not exceed the amount that would have been streamed if the stream had a
    /// granularity of 1.
    function invariant_StreamedAmountLteStreamedAmountIfGranularity1() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.getLockupModel(streamId) == Lockup.Model.LOCKUP_LINEAR) {
                // Calculate the amount that would have been streamed if the stream had a granularity of 1.
                uint128 streamedAmountIfGranularity1 = calculateStreamedAmountLL({
                    startTime: lockup.getStartTime(streamId),
                    cliffTime: lockup.getCliffTime(streamId),
                    endTime: lockup.getEndTime(streamId),
                    depositAmount: lockup.getDepositedAmount(streamId),
                    unlockAmounts: lockup.getUnlockAmounts(streamId),
                    granularity: 1 seconds
                });

                assertLe(
                    lockup.streamedAmountOf(streamId),
                    streamedAmountIfGranularity1,
                    "Invariant violation: streamed amount > amount that would have been streamed if granularity = 1"
                );
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                LT MODEL INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Unordered tranche timestamps are not allowed.
    function invariant_TrancheTimestampsOrdered() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.getLockupModel(streamId) == Lockup.Model.LOCKUP_TRANCHED) {
                LockupTranched.Tranche[] memory tranches = lockup.getTranches(streamId);
                uint40 previousTimestamp = tranches[0].timestamp;
                for (uint256 j = 1; j < tranches.length; ++j) {
                    assertGt(
                        tranches[j].timestamp, previousTimestamp, "Invariant violation: tranche timestamps not ordered"
                    );
                    previousTimestamp = tranches[j].timestamp;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                LPG MODEL INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev For a canceled LPG stream, refunded amount must equal the deposited amount.
    function invariant_CanceledLPGRefundedEqDeposited() external view {
        uint256 lastStreamId = store.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = store.streamIds(i);
            if (lockup.getLockupModel(streamId) == Lockup.Model.LOCKUP_PRICE_GATED) {
                uint128 refunded = lockup.getRefundedAmount(streamId);
                if (lockup.statusOf(streamId) == Lockup.Status.CANCELED) {
                    assertEq(
                        refunded,
                        lockup.getDepositedAmount(streamId),
                        "Invariant violation: canceled LPG stream refunded != deposited"
                    );
                }
            }
        }
    }
}
