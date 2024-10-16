// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

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
            vm.warp({ newTimestamp: uint40(flow.depletionTimeOf(streamId)) - 1 });
        }

        vars.previousAggregateAmount = flow.aggregateBalance(token);
        vars.previousTotalDebt = flow.totalDebtOf(streamId);
        vars.previousTokenBalance = token.balanceOf(address(flow));
        vars.previousStreamBalance = flow.getBalance(streamId);

        uint128 withdrawAmount = flow.withdrawableAmountOf(streamId);

        vars.expectedSnapshotTime = getBlockTimestamp();

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: withdrawTo, value: withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.WithdrawFromFlowStream({
            streamId: streamId,
            to: withdrawTo,
            token: token,
            caller: caller,
            protocolFeeAmount: 0,
            withdrawAmount: withdrawAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Withdraw the tokens.
        (vars.actualWithdrawnAmount, vars.actualProtocolFeeAmount) = flow.withdrawMax(streamId, withdrawTo);

        // Check the return values.
        assertEq(vars.actualWithdrawnAmount, withdrawAmount, "withdrawn amount");
        assertEq(vars.actualProtocolFeeAmount, 0, "protocol fee amount");

        assertEq(flow.ongoingDebtScaledOf(streamId), 0, "ongoing debt");

        // It should update snapshot time.
        assertEq(flow.getSnapshotTime(streamId), vars.expectedSnapshotTime, "snapshot time");

        // It should decrease the total debt by the withdrawn value.
        vars.actualTotalDebt = flow.totalDebtOf(streamId);
        vars.expectedTotalDebt = vars.previousTotalDebt - withdrawAmount;
        assertEq(vars.actualTotalDebt, vars.expectedTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn amount.
        vars.actualStreamBalance = flow.getBalance(streamId);
        vars.expectedStreamBalance = vars.previousStreamBalance - withdrawAmount;
        assertEq(vars.actualStreamBalance, vars.expectedStreamBalance, "stream balance");

        // Assert that total debt equals snapshot debt and ongoing debt
        assertEq(
            flow.totalDebtOf(streamId),
            getDescaledAmount(
                flow.getSnapshotDebtScaled(streamId) + flow.ongoingDebtScaledOf(streamId),
                flow.getTokenDecimals(streamId)
            ),
            "snapshot debt"
        );

        // It should reduce the token balance of stream.
        vars.actualTokenBalance = token.balanceOf(address(flow));
        vars.expectedTokenBalance = vars.previousTokenBalance - withdrawAmount;
        assertEq(vars.actualTokenBalance, vars.expectedTokenBalance, "token balance");

        // Assert that aggregate amount has been updated.
        vars.actualAggregateAmount = flow.aggregateBalance(token);
        vars.expectedAggregateAmount = vars.previousAggregateAmount - withdrawAmount;
        assertEq(vars.actualAggregateAmount, vars.expectedAggregateAmount, "aggregate amount");
    }
}
