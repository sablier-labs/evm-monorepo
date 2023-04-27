// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { console2 } from "forge-std/console2.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../Fuzz.t.sol";

abstract contract WithdrawMultiple_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint40 internal immutable EARLY_STOP_TIME;
    address internal caller;

    constructor() {
        EARLY_STOP_TIME = WARP_26_PERCENT;
    }

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) { }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenArraysEqual() {
        _;
    }

    modifier whenNoNull() {
        _;
    }

    modifier whenNoStatusPendingOrDepleted() {
        _;
    }

    /// @dev This modifier runs the test in three different modes:
    /// - Stream's sender as caller
    /// - Stream's recipient as caller
    /// - Approved NFT operator as caller
    modifier whenCallerAuthorizedAllStreams() {
        caller = users.sender;
        _;
        vm.warp({ timestamp: MARCH_1_2023 });
        caller = users.recipient;
        _;
        vm.warp({ timestamp: MARCH_1_2023 });
        changePrank({ msgSender: users.recipient });
        lockup.setApprovalForAll({ operator: users.operator, _approved: true });
        caller = users.operator;
        _;
    }

    modifier whenNoAmountZero() {
        _;
    }

    modifier whenNoAmountOverdraws() {
        _;
    }

    function testFuzz_WithdrawMultiple(
        uint256 timeWarp,
        address to,
        uint128 ongoingWithdrawAmount
    )
        external
        whenNoDelegateCall
        whenToNonZeroAddress
        whenArraysEqual
        whenNoNull
        whenNoStatusPendingOrDepleted
        whenCallerAuthorizedAllStreams
        whenNoAmountZero
        whenNoAmountOverdraws
    {
        vm.assume(to != address(0));
        timeWarp = bound(timeWarp, DEFAULT_TOTAL_DURATION, DEFAULT_TOTAL_DURATION * 2 - 1 seconds);

        // Hard code the withdrawal address if the caller is the stream's sender.
        if (caller == users.sender) {
            to = users.recipient;
        }

        // Create a new stream with an end time nearly double that of the default stream.
        changePrank({ msgSender: users.sender });
        uint40 ongoingEndTime = DEFAULT_END_TIME + DEFAULT_TOTAL_DURATION;
        uint256 ongoingStreamId = createDefaultStreamWithEndTime(ongoingEndTime);

        // Create and use a default stream as the settled stream.
        uint256 settledStreamId = createDefaultStream();
        uint128 settledWithdrawAmount = DEFAULT_DEPOSIT_AMOUNT;

        // Run the test with the caller provided in the modifier above.
        changePrank({ msgSender: caller });

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the ongoing withdraw amount.
        uint128 ongoingWithdrawableAmount = lockup.withdrawableAmountOf(ongoingStreamId);
        ongoingWithdrawAmount = boundUint128(ongoingWithdrawAmount, 1, ongoingWithdrawableAmount);

        // Expect the withdrawals to be made.
        expectTransferCall({ to: to, amount: ongoingWithdrawAmount });
        expectTransferCall({ to: to, amount: settledWithdrawAmount });

        // Expect multiple events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: ongoingStreamId, to: to, amount: ongoingWithdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: settledStreamId, to: to, amount: settledWithdrawAmount });

        // Make the withdrawals.
        uint256[] memory streamIds = Solarray.uint256s(ongoingStreamId, settledStreamId);
        uint128[] memory amounts = Solarray.uint128s(ongoingWithdrawAmount, settledWithdrawAmount);
        lockup.withdrawMultiple({ streamIds: streamIds, to: to, amounts: amounts });

        // Assert that the statuses have been updated.
        assertEq(lockup.statusOf(streamIds[0]), Lockup.Status.STREAMING, "status0");
        assertEq(lockup.statusOf(streamIds[1]), Lockup.Status.DEPLETED, "status1");

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(streamIds[0]), amounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(streamIds[1]), amounts[1], "withdrawnAmount1");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(streamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(streamIds[1]), users.recipient, "NFT owner1");
    }
}
