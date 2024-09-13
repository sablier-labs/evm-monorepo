// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawMax_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should withdraw the max covered debt from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Only two values for caller (stream owner and approved operator).
    /// - Multiple non-zero values for withdrawTo address.
    /// - Multiple streams to withdraw from, each with different token decimals and rps.
    /// - Multiple points in time.
    function testFuzz_WithdrawalAddressNotOwner(
        address withdrawTo,
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
    {
        vm.assume(withdrawTo != address(0) && withdrawTo != address(flow));

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Prank to either recipient or operator.
        address caller = useRecipientOrOperator(streamId, timeJump);
        resetPrank({ msgSender: caller });

        // Withdraw the tokens.
        _test_WithdrawMax(caller, withdrawTo, streamId);
    }

    /// @dev Checklist:
    /// - It should withdraw the max withdrawable amount from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for callers.
    /// - Multiple streams to withdraw from, each with different token decimals and rps.
    /// - Multiple points in time.
    function testFuzz_WithdrawMax(
        address caller,
        uint256 streamId,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
        givenNotPaused
        whenWithdrawalAddressOwner
    {
        vm.assume(caller != address(0));

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Prank the caller and withdraw the tokens.
        resetPrank(caller);
        _test_WithdrawMax(caller, users.recipient, streamId);
    }

    // Shared private function.
    function _test_WithdrawMax(address caller, address withdrawTo, uint256 streamId) private {
        // If the withdrawable amount is still zero, warp closely to depletion time.
        if (flow.withdrawableAmountOf(streamId) == 0) {
            vm.warp({ newTimestamp: flow.depletionTimeOf(streamId) - 1 });
        }

        uint128 totalDebt = flow.totalDebtOf(streamId);
        uint256 tokenBalance = token.balanceOf(address(flow));
        uint128 streamBalance = flow.getBalance(streamId);

        uint128 withdrawAmount = flow.withdrawableAmountOf(streamId);

        uint40 expectedSnapshotTime = getBlockTimestamp();

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: withdrawTo, value: withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: withdrawTo,
            token: token,
            caller: caller,
            protocolFeeAmount: 0,
            withdrawAmount: withdrawAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Withdraw the tokens.
        flow.withdrawMax(streamId, withdrawTo);

        assertEq(flow.ongoingDebtOf(streamId), 0, "ongoing debt");

        // It should update snapshot time.
        assertEq(flow.getSnapshotTime(streamId), expectedSnapshotTime, "snapshot time");

        // It should decrease the total debt by the withdrawn value.
        uint128 actualTotalDebt = flow.totalDebtOf(streamId);
        uint128 expectedTotalDebt = totalDebt - withdrawAmount;
        assertEq(actualTotalDebt, expectedTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn amount.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = streamBalance - withdrawAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // Assert that snapshot time is updated correctly.
        assertEq(flow.getSnapshotTime(streamId), expectedSnapshotTime, "snapshot time");

        // Assert that total debt equals snapshot debt and ongoing debt
        assertEq(
            flow.totalDebtOf(streamId), flow.getSnapshotDebt(streamId) + flow.ongoingDebtOf(streamId), "snapshot debt"
        );

        // It should reduce the token balance of stream.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = tokenBalance - withdrawAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balance");
    }
}
