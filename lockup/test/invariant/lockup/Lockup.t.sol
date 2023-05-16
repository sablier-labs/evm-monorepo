// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Invariant_Test } from "../Invariant.t.sol";
import { LockupHandler } from "../handlers/LockupHandler.t.sol";
import { LockupHandlerStorage } from "../handlers/LockupHandlerStorage.t.sol";

/// @title Lockup_Invariant_Test
/// @notice Common invariant test logic needed across contracts that inherit from {SablierV2Lockup}.
abstract contract Lockup_Invariant_Test is Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Lockup internal lockup;
    LockupHandler internal lockupHandler;
    LockupHandlerStorage internal lockupHandlerStorage;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Invariant_Test.setUp();

        // Deploy and label the handler storage contract.
        lockupHandlerStorage = new LockupHandlerStorage();
        vm.label({ account: address(lockupHandlerStorage), newLabel: "LockupHandlerStorage" });

        // Exclude the lockup handler store from being fuzzed as `msg.sender`.
        excludeSender(address(lockupHandlerStorage));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    // solhint-disable max-line-length
    function invariant_ContractBalance() external {
        uint256 contractBalance = dai.balanceOf(address(lockup));
        uint256 protocolRevenues = lockup.protocolRevenues(dai);

        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        uint256 depositedAmountsSum;
        uint256 refundedAmountsSum;
        uint256 withdrawnAmountsSum;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            depositedAmountsSum += uint256(lockup.getDepositedAmount(streamId));
            refundedAmountsSum += uint256(lockup.getRefundedAmount(streamId));
            withdrawnAmountsSum += uint256(lockup.getWithdrawnAmount(streamId));
        }

        assertGte(
            contractBalance,
            depositedAmountsSum + protocolRevenues - refundedAmountsSum - withdrawnAmountsSum,
            unicode"Invariant violation: contract balances < Σ deposited amounts + protocol revenues - Σ refunded amounts - Σ withdrawn amounts"
        );
    }

    function invariant_DepositedAmountGteStreamedAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositedAmount(streamId),
                lockup.streamedAmountOf(streamId),
                "Invariant violation: deposited amount < streamed amount"
            );
        }
    }

    function invariant_DepositedAmountGteWithdrawableAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositedAmount(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violation: deposited amount < withdrawable amount"
            );
        }
    }

    function invariant_DepositedAmountGteWithdrawnAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositedAmount(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violation: deposited amount < withdrawn amount"
            );
        }
    }

    function invariant_EndTimeGtStartTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGt(
                lockup.getEndTime(streamId),
                lockup.getStartTime(streamId),
                "Invariant violation: end time <= start time"
            );
        }
    }

    function invariant_NextStreamId() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = lockup.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream id not incremented");
        }
    }

    function invariant_StatusCanceled() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
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

    function invariant_StatusDepleted() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
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

    function invariant_StatusPending() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
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

    function invariant_StatusSettled() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
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

    function invariant_StatusStreaming() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
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

    /// @dev See diagram at https://ipfs.io/ipfs/bafkreihdoin3zn3yjkhxsx2cnqpr235shepgis36dqwqiepnhhtokowq7a.
    function invariant_StatusTransitions() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        if (lastStreamId == 0) {
            return;
        }

        for (uint256 i = 0; i < lastStreamId - 1; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            Lockup.Status currentStatus = lockup.statusOf(streamId);

            // If this is the first time the status is checked for this stream, skip the invariant test.
            if (!lockupHandlerStorage.isPreviousStatusRecorded(streamId)) {
                lockupHandlerStorage.updateIsPreviousStatusRecorded(streamId);
                return;
            }

            // Check the status transition invariants.
            Lockup.Status previousStatus = lockupHandlerStorage.previousStatusOf(streamId);
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
                assertNotEq(
                    currentStatus, Lockup.Status.STREAMING, "Invariant violation: settled stream turned streaming"
                );
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
            lockupHandlerStorage.updatePreviousStatusOf(streamId, currentStatus);
        }
    }

    function invariant_StreamedAmountGteWithdrawableAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.streamedAmountOf(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violation: streamed amount < withdrawable amount"
            );
        }
    }

    function invariant_StreamedAmountGteWithdrawnAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.streamedAmountOf(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violation: streamed amount < withdrawn amount"
            );
        }
    }
}
