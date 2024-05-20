// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Invariant_Test } from "./Invariant.t.sol";
import { OpenEndedHandler } from "./handlers/OpenEndedHandler.sol";
import { OpenEndedCreateHandler } from "./handlers/OpenEndedCreateHandler.sol";
import { OpenEndedStore } from "./stores/OpenEndedStore.sol";

/// @notice Common invariant test logic needed across contracts that inherit from {SablierV2openEnded}.
contract OpenEnded_Invariant_Test is Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    OpenEndedHandler internal openEndedHandler;
    OpenEndedCreateHandler internal openEndedCreateHandler;
    OpenEndedStore internal openEndedStore;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Invariant_Test.setUp();

        // Deploy and the OpenEndedStore contract.
        openEndedStore = new OpenEndedStore();

        // Deploy the handlers.
        openEndedHandler = new OpenEndedHandler({
            asset_: dai,
            timestampStore_: timestampStore,
            openEndedStore_: openEndedStore,
            openEnded_: openEnded
        });
        openEndedCreateHandler = new OpenEndedCreateHandler({
            asset_: dai,
            timestampStore_: timestampStore,
            openEndedStore_: openEndedStore,
            openEnded_: openEnded
        });

        // Label the contracts.
        vm.label({ account: address(openEndedStore), newLabel: "openEndedStore" });
        vm.label({ account: address(openEndedHandler), newLabel: "openEndedHandler" });
        vm.label({ account: address(openEndedCreateHandler), newLabel: "openEndedCreateHandler" });

        // Target the openEnded handlers for invariant testing.
        targetContract(address(openEndedHandler));
        targetContract(address(openEndedCreateHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(openEndedStore));
        excludeSender(address(openEndedHandler));
        excludeSender(address(openEndedCreateHandler));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    function invariant_BlockTimestampGeLastTimeUpdate() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            assertGe(
                uint40(block.timestamp),
                openEnded.getLastTimeUpdate(streamId),
                "Invariant violation: block timestamp < last time update"
            );
        }
    }

    function invariant_ContractBalanceGeStreamBalancesAndRemainingAmountsSum() external useCurrentTimestamp {
        uint256 contractBalance = dai.balanceOf(address(openEnded));

        uint256 lastStreamId = openEndedStore.lastStreamId();
        uint256 streamBalancesSumNormalized;
        uint256 remainingAmountsSumNormalized;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            streamBalancesSumNormalized += uint256(normalizeBalance(streamId));
            remainingAmountsSumNormalized +=
                uint256(normalizeTransferAmount(streamId, openEndedStore.remainingAmountsSum(streamId)));
        }

        assertGe(
            contractBalance,
            streamBalancesSumNormalized + remainingAmountsSumNormalized,
            unicode"Invariant violation: contract balanceOf < Σ stream balances + remaining amounts normalized"
        );
    }

    function invariant_DepositedAmountsSumGeExtractedAmountsSumPlusRemainingAmount() external useCurrentTimestamp {
        uint256 streamDepositedAmountsSum = openEndedStore.streamDepositedAmountsSum();
        uint256 streamExtractedAmountsSum = openEndedStore.streamExtractedAmountsSum();

        assertGe(
            streamDepositedAmountsSum,
            streamExtractedAmountsSum,
            "Invariant violation: stream deposited amounts sum < stream extracted amounts sum"
        );
    }

    function invariant_NextStreamId() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = openEnded.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violation: next stream id not incremented");
        }
    }

    function invariant_StreamBalanceEqWithdrawableAmountPlusRefundableAmountMinusRemainingAmount()
        external
        useCurrentTimestamp
    {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (!openEnded.isCanceled(streamId)) {
                assertEq(
                    openEnded.getBalance(streamId),
                    openEnded.withdrawableAmountOf(streamId) + openEnded.refundableAmountOf(streamId)
                        - openEnded.getRemainingAmount(streamId),
                    "Invariant violation: stream balance != withdrawable amount + refundable amount - remaining amount"
                );
            }
        }
    }

    function invariant_StreamBalanceGeRefundableAmount() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (!openEnded.isCanceled(streamId)) {
                assertGe(
                    openEnded.getBalance(streamId),
                    openEnded.refundableAmountOf(streamId),
                    "Invariant violation: stream balance < refundable amount"
                );
            }
        }
    }

    function invariatn_StreamCanceled_BalanceZero() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (openEnded.isCanceled(streamId)) {
                assertEq(
                    openEnded.getBalance(streamId), 0, "Invariant violation: canceled stream with a non-zero balance"
                );
            }
        }
    }

    function invariant_StreamCanceled_RatePerSecondZero() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (openEnded.isCanceled(streamId)) {
                assertEq(
                    openEnded.getRatePerSecond(streamId),
                    0,
                    "Invariant violation: canceled stream with a non-zero rate per second"
                );
            }
        }
    }

    function invariant_StreamedCanceled_WithdrawableAmountEqRemainingAmount() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (openEnded.isCanceled(streamId)) {
                assertEq(
                    openEnded.withdrawableAmountOf(streamId),
                    openEnded.getRemainingAmount(streamId),
                    "Invariant violation: canceled stream withdrawable amount != remaining amount"
                );
            }
        }
    }

    /// @dev The invariant is: withdrawable amount = min(balance, streamed amount) + remaining amount
    /// This includes both canceled and non-canceled streams.
    function invariant_WithdrawableAmount() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            uint128 balance = openEnded.getBalance(streamId);
            uint128 streamedAmount = 0;

            if (!openEnded.isCanceled(streamId)) {
                streamedAmount = openEnded.streamedAmountOf(streamId);
            }

            uint128 balanceOrStreamedAmount = balance > streamedAmount ? streamedAmount : balance;

            assertEq(
                openEnded.withdrawableAmountOf(streamId),
                balanceOrStreamedAmount + openEnded.getRemainingAmount(streamId),
                "Invariant violation: withdrawable amount != min(balance, streamed amount) + remaining amount"
            );
        }
    }
}
