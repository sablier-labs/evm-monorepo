// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";
import { ISablierLockupBase } from "src/core/interfaces/ISablierLockupBase.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

abstract contract WithdrawMultiple_Integration_Concrete_Test is Integration_Test {
    address internal caller;

    // The original time when the tests started.
    uint40 internal originalTime;

    function setUp() public virtual override {
        originalTime = getBlockTimestamp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierLockupBase.withdrawMultiple, (withdrawMultipleStreamIds, withdrawAmounts));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_UnequalArraysLength() external whenNoDelegateCall {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupBase_WithdrawArrayCountsNotEqual.selector, streamIds.length, amounts.length
            )
        );
        lockup.withdrawMultiple(streamIds, amounts);
    }

    function test_WhenZeroArrayLength() external whenNoDelegateCall whenEqualArraysLength {
        uint256[] memory streamIds = new uint256[](0);
        uint128[] memory amounts = new uint128[](0);

        // It should do nothing.
        lockup.withdrawMultiple(streamIds, amounts);
    }

    function test_RevertGiven_AtleastOneNullStream()
        external
        whenNoDelegateCall
        whenEqualArraysLength
        whenNonZeroArrayLength
    {
        uint256[] memory streamIds =
            Solarray.uint256s(withdrawMultipleStreamIds[0], withdrawMultipleStreamIds[1], nullStreamId);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockupBase_Null.selector, nullStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, amounts: withdrawAmounts });
    }

    function test_RevertGiven_AtleastOneDEPLETEDStream()
        external
        whenNoDelegateCall
        whenEqualArraysLength
        whenNonZeroArrayLength
        givenNoNullStreams
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // Deplete the first test stream.
        lockup.withdrawMax({ streamId: withdrawMultipleStreamIds[0], to: users.recipient });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_StreamDepleted.selector, withdrawMultipleStreamIds[0])
        );

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: withdrawMultipleStreamIds, amounts: withdrawAmounts });
    }

    function test_RevertWhen_AtleastOneZeroAmount()
        external
        whenNoDelegateCall
        whenEqualArraysLength
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoDEPLETEDStreams
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(defaults.WITHDRAW_AMOUNT(), 0, 0);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockupBase_WithdrawAmountZero.selector, withdrawMultipleStreamIds[1])
        );
        lockup.withdrawMultiple({ streamIds: withdrawMultipleStreamIds, amounts: amounts });
    }

    function test_RevertWhen_AtleastOneAmountOverdraws()
        external
        whenNoDelegateCall
        whenEqualArraysLength
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoDEPLETEDStreams
        whenNoZeroAmounts
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Run the test.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(withdrawMultipleStreamIds[2]);
        uint128[] memory amounts = Solarray.uint128s(withdrawAmounts[0], withdrawAmounts[1], MAX_UINT128);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockupBase_Overdraw.selector,
                withdrawMultipleStreamIds[2],
                MAX_UINT128,
                withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: withdrawMultipleStreamIds, amounts: amounts });
    }

    function test_WhenNoAmountsOverdraw()
        external
        whenNoDelegateCall
        whenEqualArraysLength
        whenNonZeroArrayLength
        givenNoNullStreams
        givenNoDEPLETEDStreams
        whenNoZeroAmounts
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Cancel the 3rd stream.
        resetPrank({ msgSender: users.sender });
        lockup.cancel(withdrawMultipleStreamIds[2]);

        // Run the test with the caller provided in {whenCallerAuthorizedForAllStreams}.
        resetPrank({ msgSender: caller });

        // It should make the withdrawals.
        expectCallToTransfer({ to: users.recipient, value: withdrawAmounts[0] });
        expectCallToTransfer({ to: users.recipient, value: withdrawAmounts[1] });
        expectCallToTransfer({ to: users.recipient, value: withdrawAmounts[2] });

        // It should emit multiple {WithdrawFromLockupStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: withdrawMultipleStreamIds[0],
            to: users.recipient,
            asset: dai,
            amount: withdrawAmounts[0]
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: withdrawMultipleStreamIds[1],
            to: users.recipient,
            asset: dai,
            amount: withdrawAmounts[1]
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupBase.WithdrawFromLockupStream({
            streamId: withdrawMultipleStreamIds[2],
            to: users.recipient,
            asset: dai,
            amount: withdrawAmounts[2]
        });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: withdrawMultipleStreamIds, amounts: withdrawAmounts });

        // It should update the statuses.
        assertEq(lockup.statusOf(withdrawMultipleStreamIds[0]), Lockup.Status.STREAMING, "status0");
        assertEq(lockup.statusOf(withdrawMultipleStreamIds[1]), Lockup.Status.DEPLETED, "status1");
        assertEq(lockup.statusOf(withdrawMultipleStreamIds[2]), Lockup.Status.CANCELED, "status2");

        // It should update the withdrawn amounts.
        assertEq(lockup.getWithdrawnAmount(withdrawMultipleStreamIds[0]), withdrawAmounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(withdrawMultipleStreamIds[1]), withdrawAmounts[1], "withdrawnAmount1");
        assertEq(lockup.getWithdrawnAmount(withdrawMultipleStreamIds[2]), withdrawAmounts[2], "withdrawnAmount2");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(withdrawMultipleStreamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(withdrawMultipleStreamIds[1]), users.recipient, "NFT owner1");
        assertEq(lockup.getRecipient(withdrawMultipleStreamIds[2]), users.recipient, "NFT owner2");
    }
}
