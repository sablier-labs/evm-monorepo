// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Solarray } from "solarray/Solarray.sol";

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { WithdrawMultiple_Shared_Test } from "../../../shared/lockup/withdraw-multiple/withdrawMultiple.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract WithdrawMultiple_Unit_Test is Unit_Test, WithdrawMultiple_Shared_Test {
    function setUp() public virtual override(Unit_Test, WithdrawMultiple_Shared_Test) {
        WithdrawMultiple_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2Lockup.withdrawMultiple, (testStreamIds, users.recipient, testAmounts));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_ArrayCountsNotEqual() external whenNoDelegateCall {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawArrayCountsNotEqual.selector, streamIds.length, amounts.length
            )
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsAreEqual() {
        _;
    }

    function test_WithdrawMultiple_ArrayCountsZero() external whenNoDelegateCall whenArrayCountsAreEqual {
        uint256[] memory streamIds = new uint256[](0);
        uint128[] memory amounts = new uint128[](0);
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    modifier whenArrayCountsNotZero() {
        _;
    }

    function test_RevertWhen_OnlyNull() external whenNoDelegateCall whenArrayCountsAreEqual whenArrayCountsNotZero {
        uint256 nullStreamId = 1729;
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdrawMultiple({
            streamIds: Solarray.uint256s(nullStreamId),
            to: users.recipient,
            amounts: Solarray.uint128s(withdrawAmount)
        });
    }

    function test_RevertWhen_SomeNull() external whenNoDelegateCall whenArrayCountsAreEqual whenArrayCountsNotZero {
        uint256 nullStreamId = 1729;
        uint256[] memory streamIds = Solarray.uint256s(testStreamIds[0], testStreamIds[1], nullStreamId);

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Expect a {Null} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: testAmounts });
    }

    function test_RevertWhen_AllStatusesDepleted()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
    {
        uint256[] memory streamIds = Solarray.uint256s(testStreamIds[0]);
        uint128[] memory amounts = Solarray.uint128s(defaults.WITHDRAW_AMOUNT());

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.END_TIME() });

        // Deplete the first test stream.
        lockup.withdrawMax({ streamId: testStreamIds[0], to: users.recipient });

        // Expect a {StreamDepleted} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, testStreamIds[0]));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: amounts });
    }

    function test_RevertWhen_SomeStatusesDepleted()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.END_TIME() });

        // Deplete the first test stream.
        lockup.withdrawMax({ streamId: testStreamIds[0], to: users.recipient });

        // Expect a {StreamDepleted} error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, testStreamIds[0]));

        // Withdraw from multiple streams.
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: testAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: testAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerUnauthorized
    {
        // Transfer all streams to Alice.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[0] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[1] });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[2] });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: testAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerUnauthorized
    {
        // Create a stream with Eve as the recipient.
        uint256 eveStreamId = createDefaultStreamWithRecipient(users.eve);

        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Run the test.
        uint256[] memory streamIds = Solarray.uint256s(eveStreamId, testStreamIds[0], testStreamIds[1]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.eve)
        );
        lockup.withdrawMultiple({ streamIds: streamIds, to: users.recipient, amounts: testAmounts });
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_FormerRecipient()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerUnauthorized
    {
        // Transfer one of the streams to Eve.
        changePrank({ msgSender: users.recipient });
        lockup.transferFrom({ from: users.recipient, to: users.alice, tokenId: testStreamIds[0] });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, testStreamIds[0], users.recipient)
        );
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: testAmounts });
    }

    function test_RevertWhen_ToZeroAddress()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerAuthorizedAllStreams
    {
        if (caller == users.sender) {
            return;
        }
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: address(0), amounts: testAmounts });
    }

    function test_RevertWhen_SomeAmountsZero()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerAuthorizedAllStreams
        whenToNonZeroAddress
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Run the test.
        uint128[] memory amounts = Solarray.uint128s(defaults.WITHDRAW_AMOUNT(), 0, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, testStreamIds[1]));
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: amounts });
    }

    function test_RevertWhen_SomeAmountsOverdraw()
        external
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerAuthorizedAllStreams
        whenToNonZeroAddress
        whenNoAmountZero
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Run the test.
        uint128 withdrawableAmount = lockup.withdrawableAmountOf(testStreamIds[2]);
        uint128[] memory amounts = Solarray.uint128s(testAmounts[0], testAmounts[1], MAX_UINT128);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_Overdraw.selector, testStreamIds[2], MAX_UINT128, withdrawableAmount
            )
        );
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: amounts });
    }

    /// @dev TODO: mark this test as `external` once Foundry reverts this breaking change:
    /// https://github.com/foundry-rs/foundry/pull/4845#issuecomment-1529125648
    function test_WithdrawMultiple()
        private
        whenNoDelegateCall
        whenArrayCountsAreEqual
        whenArrayCountsNotZero
        whenNoNull
        whenNoDepletedStream
        whenCallerAuthorizedAllStreams
        whenToNonZeroAddress
        whenNoAmountZero
        whenNoAmountOverdraws
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: earlyStopTime });

        // Cancel the 3rd stream.
        lockup.cancel(testStreamIds[2]);

        // Expect the withdrawals to be made.
        expectCallToTransfer({ to: users.recipient, amount: testAmounts[0] });
        expectCallToTransfer({ to: users.recipient, amount: testAmounts[1] });
        expectCallToTransfer({ to: users.recipient, amount: testAmounts[2] });

        // Expect multiple events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: testStreamIds[0], to: users.recipient, amount: testAmounts[0] });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: testStreamIds[1], to: users.recipient, amount: testAmounts[1] });
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: testStreamIds[2], to: users.recipient, amount: testAmounts[2] });

        // Make the withdrawals.
        lockup.withdrawMultiple({ streamIds: testStreamIds, to: users.recipient, amounts: testAmounts });

        // Assert that the statuses have been updated.
        assertEq(lockup.statusOf(testStreamIds[0]), Lockup.Status.STREAMING, "status0");
        assertEq(lockup.statusOf(testStreamIds[1]), Lockup.Status.DEPLETED, "status1");
        assertEq(lockup.statusOf(testStreamIds[2]), Lockup.Status.CANCELED, "status2");

        // Assert that the withdrawn amounts have been updated.
        assertEq(lockup.getWithdrawnAmount(testStreamIds[0]), testAmounts[0], "withdrawnAmount0");
        assertEq(lockup.getWithdrawnAmount(testStreamIds[1]), testAmounts[1], "withdrawnAmount1");
        assertEq(lockup.getWithdrawnAmount(testStreamIds[2]), testAmounts[2], "withdrawnAmount2");

        // Assert that the stream NFTs have not been burned.
        assertEq(lockup.getRecipient(testStreamIds[0]), users.recipient, "NFT owner0");
        assertEq(lockup.getRecipient(testStreamIds[1]), users.recipient, "NFT owner1");
        assertEq(lockup.getRecipient(testStreamIds[2]), users.recipient, "NFT owner2");
    }
}
