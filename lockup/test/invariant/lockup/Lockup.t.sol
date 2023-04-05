// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Invariant_Test } from "../Invariant.t.sol";
import { FlashLoanHandler } from "../handlers/FlashLoanHandler.t.sol";
import { LockupHandler } from "../handlers/LockupHandler.t.sol";
import { LockupHandlerStorage } from "../handlers/LockupHandlerStorage.t.sol";

/// @title Lockup_Invariant_Test
/// @notice Common invariant test logic needed across contracts that inherit from {SablierV2Lockup}.
abstract contract Lockup_Invariant_Test is Invariant_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    FlashLoanHandler internal flashLoanHandler;
    ISablierV2Lockup internal lockup;
    LockupHandler internal lockupHandler;
    LockupHandlerStorage internal lockupHandlerStorage;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Invariant_Test.setUp();

        // Deploy the lockupHandlerStorage.
        lockupHandlerStorage = new LockupHandlerStorage();

        // Exclude the lockup handler store from being `msg.sender`.
        excludeSender(address(lockupHandlerStorage));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INVARIANTS
    //////////////////////////////////////////////////////////////////////////*/

    // solhint-disable max-line-length
    function invariant_ContractBalance() external {
        uint256 contractBalance = DEFAULT_ASSET.balanceOf(address(lockup));
        uint256 protocolRevenues = lockup.protocolRevenues(DEFAULT_ASSET);

        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        uint256 depositAmountsSum;
        uint256 returnedAmountsSum;
        uint256 withdrawnAmountsSum;
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            depositAmountsSum += uint256(lockup.getDepositAmount(streamId));
            returnedAmountsSum += uint256(lockup.getReturnedAmount(streamId));
            withdrawnAmountsSum += uint256(lockup.getWithdrawnAmount(streamId));
        }

        assertGte(
            contractBalance,
            depositAmountsSum + protocolRevenues - returnedAmountsSum - withdrawnAmountsSum,
            unicode"Invariant violated: contract balances < Σ deposit amounts + protocol revenues - Σ returned amounts - Σ withdrawn amounts"
        );
    }

    function invariant_DepositAmountGteStreamedAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositAmount(streamId),
                lockup.streamedAmountOf(streamId),
                "Invariant violated: deposit amount < streamed amount"
            );
        }
    }

    function invariant_DepositAmountGteWithdrawableAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositAmount(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violated: deposit amount < withdrawable amount"
            );
        }
    }

    function invariant_DepositAmountGteWithdrawnAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.getDepositAmount(streamId),
                lockup.getWithdrawnAmount(streamId),
                "Invariant violated: deposit amount < withdrawn amount"
            );
        }
    }

    function invariant_EndTimeGtStartTime() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGt(
                lockup.getEndTime(streamId), lockup.getStartTime(streamId), "Invariant violated: end time < start time"
            );
        }
    }

    function invariant_NextStreamIdIncrement() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 nextStreamId = lockup.nextStreamId();
            assertEq(nextStreamId, lastStreamId + 1, "Invariant violated: nonce did not increment");
        }
    }

    function invariant_StreamedAmountGteWithdrawableAmount() external {
        uint256 lastStreamId = lockupHandlerStorage.lastStreamId();
        for (uint256 i = 0; i < lastStreamId; ++i) {
            uint256 streamId = lockupHandlerStorage.streamIds(i);
            assertGte(
                lockup.streamedAmountOf(streamId),
                lockup.withdrawableAmountOf(streamId),
                "Invariant violated: streamed amount < withdrawable amount"
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
                "Invariant violated: streamed amount < withdrawn amount"
            );
        }
    }
}
