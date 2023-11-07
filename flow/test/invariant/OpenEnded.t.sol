// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20 <0.9.0;

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

    function invariant_ContractBalanceGeStreamBalancesSumNormalized() external useCurrentTimestamp {
        uint256 contractBalance = dai.balanceOf(address(openEnded));

        uint256 lastStreamId = openEndedStore.lastStreamId();
        uint256 streamBalancesSumNormalized;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            streamBalancesSumNormalized += uint256(normalizeBalance(streamId));
        }

        assertGe(
            contractBalance,
            streamBalancesSumNormalized,
            unicode"Invariant violation: contract balances < Σ stream balances normalized"
        );
    }

    function invariant_DepositedAmountsSumGeExtractedAmountsSum() external useCurrentTimestamp {
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

    function invariant_StreamBalanceEqWithdrawableAmountPlusRefundableAmount() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (!openEnded.isCanceled(streamId)) {
                assertEq(
                    openEnded.getBalance(streamId),
                    openEnded.withdrawableAmountOf(streamId) + openEnded.refundableAmountOf(streamId),
                    "Invariant violation: stream balance != withdrawable amount + refundable amount"
                );
            }
        }
    }

    function invariant_StreamBalanceGeWithdrawableAmount() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (!openEnded.isCanceled(streamId)) {
                assertGe(
                    openEnded.getBalance(streamId),
                    openEnded.withdrawableAmountOf(streamId),
                    "Invariant violation: stream balance < withdrawable amount"
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

    function invariant_StreamedAmountGeWithdrawableAmount() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (!openEnded.isCanceled(streamId)) {
                assertGe(
                    openEnded.streamedAmountOf(streamId),
                    openEnded.withdrawableAmountOf(streamId),
                    "Invariant violation: streamed amount < withdrawable amount"
                );
            }
        }
    }

    function invariant_StreamCanceled() external useCurrentTimestamp {
        uint256 lastStreamId = openEndedStore.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = openEndedStore.streamIds(i);
            if (openEnded.isCanceled(streamId)) {
                assertEq(
                    openEnded.getratePerSecond(streamId),
                    0,
                    "Invariant violation: canceled stream with a non-zero amount per second"
                );
                assertEq(
                    openEnded.getBalance(streamId), 0, "Invariant violation: canceled stream with a non-zero balance"
                );
            }
        }
    }
}
