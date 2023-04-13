// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Fuzz_Test } from "../../../Fuzz.t.sol";

abstract contract Withdraw_Fuzz_Test is Fuzz_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Fuzz_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the current time.
    /// - Multiple values for the withdrawal address.
    /// - Multiple withdraw amounts.
    function testFuzz_Withdraw_StreamCanceled(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        whenNoDelegateCall
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Cancel the stream.
        lockup.cancel({ streamId: defaultStreamId });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the assets to be transferred to the fuzzed `to` address.
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream(defaultStreamId, to, withdrawAmount);

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: withdrawAmount });

        // Check if the stream has been depleted.
        uint128 refundedAmount = lockup.getRefundedAmount(defaultStreamId);
        bool isDepleted = withdrawAmount == DEFAULT_DEPOSIT_AMOUNT - refundedAmount;

        // Assert that the stream has remained canceled or it has been marked as depleted.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = isDepleted ? Lockup.Status.DEPLETED : Lockup.Status.CANCELED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has not been burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    modifier whenStreamActive() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenWithdrawAmountNotZero() {
        _;
    }

    modifier whenWithdrawAmountNotGreaterThanWithdrawableAmount() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the withdrawal address.
    function testFuzz_Withdraw_CallerRecipient(address to)
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function testFuzz_Withdraw_CallerApprovedOperator(address to)
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp into the future.
        vm.warp({ timestamp: WARP_TIME_26 });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple values for the withdrawal address
    /// - Multiple withdraw amounts
    function testFuzz_Withdraw(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        whenNoDelegateCall
        whenStreamActive
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenWithdrawAmountNotGreaterThanWithdrawableAmount
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);
        vm.assume(to != address(0));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(defaultStreamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the assets to be transferred to the fuzzed `to` address.
        expectTransferCall({ to: to, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream(defaultStreamId, to, withdrawAmount);

        // Make the withdrawal.
        lockup.withdraw(defaultStreamId, to, withdrawAmount);

        // Check if the stream has been depleted.
        bool isDepleted = withdrawAmount == DEFAULT_DEPOSIT_AMOUNT;

        // Assert that the stream has remained active or it has been marked as depleted.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = isDepleted ? Lockup.Status.DEPLETED : Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has not been burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }
}
