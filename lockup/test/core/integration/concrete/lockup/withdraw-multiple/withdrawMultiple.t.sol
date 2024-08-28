// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Solarray } from "solarray/src/Solarray.sol";

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";

import { WithdrawMultiple_Integration_Shared_Test } from "../../../shared/lockup/withdrawMultiple.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract WithdrawMultiple_Integration_Concrete_Test is
    Integration_Test,
    WithdrawMultiple_Integration_Shared_Test
{
    function setUp() public virtual override(Integration_Test, WithdrawMultiple_Integration_Shared_Test) {
        WithdrawMultiple_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierLockup.withdrawMultiple, (testStreamIds, testAmounts));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_UnequalArraysLength() external whenNoDelegateCall {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_WithdrawArrayCountsNotEqual.selector, streamIds.length, amounts.length
            )
        );
        lockup.withdrawMultiple(streamIds, amounts);
    }

    modifier whenEqualArraysLength() {
        _;
    }

    function test_WhenZeroArrayLength() external whenNoDelegateCall whenEqualArraysLength {
        uint256[] memory streamIds = new uint256[](0);
        uint128[] memory amounts = new uint128[](0);

        // It should do nothing.
        lockup.withdrawMultiple(streamIds, amounts);
    }

    modifier whenNonZeroArrayLength() {
        _;
    }

    function test_RevertGiven_AtleastOneNullStream()
        external
        whenNoDelegateCall
        whenEqualArraysLength
        whenNonZeroArrayLength
    {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(testStreamIds[0], testStreamIds[1], nullStreamId);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, amounts: testAmounts });
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
        lockup.withdrawMax({ streamId: testStreamIds[0], to: users.recipient });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamDepleted.selector, testStreamIds[0]));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: testStreamIds, amounts: testAmounts });
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
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_WithdrawAmountZero.selector, testStreamIds[1]));
        lockup.withdrawMultiple({ streamIds: testStreamIds, amounts: amounts });
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
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(testStreamIds[2]);
        uint128[] memory amounts = Solarray.uint128s(testAmounts[0], testAmounts[1], MAX_UINT128);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_Overdraw.selector, testStreamIds[2], MAX_UINT128, withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: testStreamIds, amounts: amounts });
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
        vm.warp({ newTimestamp: earlyStopTime });

        // Cancel the 3rd stream.
        resetPrank({ msgSender: users.sender });
        lockup.cancel(testStreamIds[2]);

        // Run the test with the caller provided in {whenCallerAuthorizedAllStreams}.
        resetPrank({ msgSender: caller });

        // It should make the withdrawals.
        expectCallToTransfer({ to: users.recipient, value: testAmounts[0] });
        expectCallToTransfer({ to: users.recipient, value: testAmounts[1] });
        expectCallToTransfer({ to: users.recipient, value: testAmounts[2] });

        // It should emit multiple {WithdrawFromLockupStream} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: testStreamIds[0],
            to: users.recipient,
            asset: dai,
            amount: testAmounts[0]
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: testStreamIds[1],
            to: users.recipient,
            asset: dai,
            amount: testAmounts[1]
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: testStreamIds[2],
            to: users.recipient,
            asset: dai,
            amount: testAmounts[2]
        });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: testStreamIds, amounts: testAmounts });

        // It should update the statuses.
        assertEq(lockup.statusOf(testStreamIds[0]), Lockup.Status.STREAMING, "status0");
        assertEq(lockup.statusOf(testStreamIds[1]), Lockup.Status.DEPLETED, "status1");
        assertEq(lockup.statusOf(testStreamIds[2]), Lockup.Status.CANCELED, "status2");

        // It should update the withdrawn amounts.
        assertEq(lockup.getWithdrawnAmount(testStreamIds[0]), testAmounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(testStreamIds[1]), testAmounts[1], "withdrawnAmount1");
        assertEq(lockup.getWithdrawnAmount(testStreamIds[2]), testAmounts[2], "withdrawnAmount2");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(testStreamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(testStreamIds[1]), users.recipient, "NFT owner1");
        assertEq(lockup.getRecipient(testStreamIds[2]), users.recipient, "NFT owner2");
    }
}
