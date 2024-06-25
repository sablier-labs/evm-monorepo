// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawAt_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev It should withdraw 0 amount from a stream.
    function testFuzz_Paused_Withdraw(
        address caller,
        uint256 streamId,
        uint40 timeJump,
        uint40 withdrawTime,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        vm.assume(caller != address(0));

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Pause the stream.
        flow.pause(streamId);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        uint40 warpTimestamp = getBlockTimestamp() + timeJump;

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Bound the withdraw time between the allowed range.
        withdrawTime = boundUint40(withdrawTime, MAY_1_2024, warpTimestamp);

        // Ensure no value is transferred.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: 0 });

        uint128 expectedAmountOwed = flow.amountOwedOf(streamId);
        uint128 expectedStreamBalance = flow.getBalance(streamId);
        uint256 expectedAssetBalance = asset.balanceOf(address(flow));

        // Change prank to caller and withdraw the assets.
        resetPrank(caller);
        flow.withdrawAt(streamId, users.recipient, withdrawTime);

        // Assert that all states are unchanged except for lastTimeUpdate.
        uint128 actualLastTimeUpdate = flow.getLastTimeUpdate(streamId);
        assertEq(actualLastTimeUpdate, withdrawTime, "last time update");

        uint128 actualAmountOwed = flow.amountOwedOf(streamId);
        assertEq(actualAmountOwed, expectedAmountOwed, "full amount owed");

        uint128 actualStreamBalance = flow.getBalance(streamId);
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        uint256 actualAssetBalance = asset.balanceOf(address(flow));
        assertEq(actualAssetBalance, expectedAssetBalance, "asset balance");
    }

    /// @dev Checklist:
    /// - It should withdraw asset from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Only two values for caller (stream owner and approved operator).
    /// - Multiple non-zero values for to address.
    /// - Multiple streams to withdraw from, each with different asset decimals and rps.
    /// - Multiple values for withdraw time in the range (lastTimeUpdate, currentTime). It could also be before or after
    /// depletion time.
    /// - Multiple points in time.
    function testFuzz_WithdrawalAddressNotOwner(
        address to,
        uint256 streamId,
        uint40 timeJump,
        uint40 withdrawTime,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
    {
        vm.assume(to != address(0) && to != address(flow));

        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Prank to either recipient or operator.
        resetPrank({ msgSender: useRecipientOrOperator(streamId, timeJump) });

        // Withdraw the assets.
        _test_WithdrawAt(to, streamId, timeJump, withdrawTime, decimals);
    }

    /// @dev Checklist:
    /// - It should withdraw asset from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for callers.
    /// - Multiple streams to withdraw from, each with different asset decimals and rps.
    /// - Multiple values for withdraw time in the range (lastTimeUpdate, currentTime). It could also be before or after
    /// depletion time.
    /// - Multiple points in time.
    function testFuzz_WithdrawAt(
        address caller,
        uint256 streamId,
        uint40 timeJump,
        uint40 withdrawTime,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenWithdrawalAddressIsOwner
    {
        vm.assume(caller != address(0));

        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Prank the caller and withdraw the assets.
        resetPrank(caller);
        _test_WithdrawAt(users.recipient, streamId, timeJump, withdrawTime, decimals);
    }

    // Shared private function.
    function _test_WithdrawAt(
        address to,
        uint256 streamId,
        uint40 timeJump,
        uint40 withdrawTime,
        uint8 decimals
    )
        private
    {
        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        uint40 warpTimestamp = getBlockTimestamp() + timeJump;

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Bound the withdraw time between the allowed range.
        withdrawTime = boundUint40(withdrawTime, MAY_1_2024, warpTimestamp);

        uint128 amountOwed = flow.amountOwedOf(streamId);
        uint256 assetbalance = asset.balanceOf(address(flow));
        uint128 streamBalance = flow.getBalance(streamId);
        uint128 expectedWithdrawAmount = flow.getRemainingAmount(streamId)
            + flow.getRatePerSecond(streamId) * (withdrawTime - flow.getLastTimeUpdate(streamId));

        if (streamBalance < expectedWithdrawAmount) {
            expectedWithdrawAmount = streamBalance;
        }

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: address(flow), to: to, value: getTransferAmount(expectedWithdrawAmount, decimals) });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({ streamId: streamId, to: to, withdrawnAmount: expectedWithdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Withdraw the assets.
        flow.withdrawAt(streamId, to, withdrawTime);

        // It should update lastTimeUpdate.
        assertEq(flow.getLastTimeUpdate(streamId), withdrawTime, "last time update");

        // It should decrease the full amount owed by withdrawn value.
        uint128 actualAmountOwed = flow.amountOwedOf(streamId);
        uint128 expectedAmountOwed = amountOwed - expectedWithdrawAmount;
        assertEq(actualAmountOwed, expectedAmountOwed, "full amount owed");

        // It should reduce the stream balance by the withdrawn amount.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = streamBalance - expectedWithdrawAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should reduce the asset balance of stream.
        uint256 actualAssetBalance = asset.balanceOf(address(flow));
        uint256 expectedAssetBalance = assetbalance - getTransferAmount(expectedWithdrawAmount, decimals);
        assertEq(actualAssetBalance, expectedAssetBalance, "asset balance");
    }
}
