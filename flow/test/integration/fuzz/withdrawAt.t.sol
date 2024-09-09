// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud, UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract WithdrawAt_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    struct Vars {
        uint40 actualSnapshotTime;
        uint256 actualStreamBalance;
        uint256 actualTokenBalance;
        uint128 actualTotalDebt;
        uint128 expectedProtocolRevenue;
        uint40 expectedSnapshotTime;
        uint128 expectedStreamBalance;
        uint256 expectedTokenBalance;
        uint128 expectedTotalDebt;
        uint128 ongoingDebt;
        uint128 streamBalance;
        uint256 tokenBalance;
        uint128 totalDebt;
        uint128 withdrawAmount;
    }

    Vars internal vars;

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
        givenProtocolFeeZero
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
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: 0 });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: users.recipient,
            token: token,
            caller: caller,
            protocolFeeAmount: 0,
            withdrawAmount: 0,
            snapshotTime: withdrawTime
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        vars.expectedTotalDebt = flow.totalDebtOf(streamId);
        vars.expectedStreamBalance = flow.getBalance(streamId);
        vars.expectedTokenBalance = token.balanceOf(address(flow));

        // Change prank to caller and withdraw the tokens.
        resetPrank(caller);
        flow.withdrawAt(streamId, users.recipient, withdrawTime);

        // Assert that all states are unchanged except for snapshotTime.
        vars.actualSnapshotTime = flow.getSnapshotTime(streamId);
        assertEq(vars.actualSnapshotTime, withdrawTime, "snapshot time");

        vars.actualTotalDebt = flow.totalDebtOf(streamId);
        assertEq(vars.actualTotalDebt, vars.expectedTotalDebt, "total debt");

        vars.actualStreamBalance = flow.getBalance(streamId);
        assertEq(vars.actualStreamBalance, vars.expectedStreamBalance, "stream balance");

        vars.actualTokenBalance = token.balanceOf(address(flow));
        assertEq(vars.actualTokenBalance, vars.expectedTokenBalance, "token balance");
    }

    /// @dev Checklist:
    /// - It should withdraw token from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Only two values for caller (stream owner and approved operator).
    /// - Multiple non-zero values for to address.
    /// - Multiple streams to withdraw from, each with different token decimals and rps.
    /// - Multiple values for withdraw time in the range (snapshotTime, currentTime). It could also be before or after
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
        givenProtocolFeeZero
    {
        vm.assume(to != address(0) && to != address(flow));

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Prank to either recipient or operator.
        address caller = useRecipientOrOperator(streamId, timeJump);
        resetPrank({ msgSender: caller });

        // Withdraw the tokens.
        _test_WithdrawAt(caller, to, streamId, timeJump, withdrawTime);
    }

    /// @dev Checklist:
    /// - It should increase protocol revenue for the token.
    /// - It should withdraw token amount after deducting protocol fee from the stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for callers.
    /// - Multiple non-zero values for protocol fee not exceeding max allowed.
    /// - Multiple streams to withdraw from, each with different token decimals and rps.
    /// - Multiple values for withdraw time in the range (snapshotTime, currentTime). It could also be before or after
    /// depletion time.
    /// - Multiple points in time.
    function testFuzz_ProtocolFeeNotZero(
        address caller,
        UD60x18 protocolFee,
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

        protocolFee = bound(protocolFee, ZERO, MAX_FEE);

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Set protocol fee.
        resetPrank(users.admin);
        flow.setProtocolFee(token, protocolFee);

        // Prank the caller and withdraw the tokens.
        resetPrank(caller);
        _test_WithdrawAt(caller, users.recipient, streamId, timeJump, withdrawTime);
    }

    /// @dev Checklist:
    /// - It should withdraw token from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {WithdrawFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for callers.
    /// - Multiple streams to withdraw from, each with different token decimals and rps.
    /// - Multiple values for withdraw time in the range (snapshotTime, currentTime). It could also be before or
    /// after
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
        givenProtocolFeeZero
    {
        vm.assume(caller != address(0));

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Prank the caller and withdraw the tokens.
        resetPrank(caller);
        _test_WithdrawAt(caller, users.recipient, streamId, timeJump, withdrawTime);
    }

    // Shared private function.
    function _test_WithdrawAt(
        address caller,
        address to,
        uint256 streamId,
        uint40 timeJump,
        uint40 withdrawTime
    )
        private
    {
        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        uint40 warpTimestamp = getBlockTimestamp() + boundUint40(timeJump, 1 seconds, 100 weeks);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: warpTimestamp });

        // Bound the withdraw time between the allowed range.
        withdrawTime = boundUint40(withdrawTime, MAY_1_2024, warpTimestamp);

        vars.tokenBalance = token.balanceOf(address(flow));
        vars.ongoingDebt = getDenormalizedAmount({
            amount: flow.getRatePerSecond(streamId).unwrap() * (withdrawTime - flow.getSnapshotTime(streamId)),
            decimals: flow.getTokenDecimals(streamId)
        });
        vars.totalDebt = flow.getSnapshotDebt(streamId) + vars.ongoingDebt;
        vars.streamBalance = flow.getBalance(streamId);
        vars.withdrawAmount = vars.streamBalance < vars.totalDebt ? vars.streamBalance : vars.totalDebt;

        vars.expectedProtocolRevenue = flow.protocolRevenue(token);

        uint128 feeAmount;
        if (flow.protocolFee(token) > ZERO) {
            feeAmount = uint128(ud(vars.withdrawAmount).mul(flow.protocolFee(token)).unwrap());
            vars.withdrawAmount -= feeAmount;
            vars.expectedProtocolRevenue += feeAmount;
        }

        // Compute the snapshot time that will be stored post withdraw.
        vars.expectedSnapshotTime = uint40(
            getNormalizedAmount(vars.ongoingDebt, flow.getTokenDecimals(streamId))
                / flow.getRatePerSecond(streamId).unwrap() + flow.getSnapshotTime(streamId)
        );

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: to, value: vars.withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: to,
            token: token,
            caller: caller,
            protocolFeeAmount: feeAmount,
            withdrawAmount: vars.withdrawAmount,
            snapshotTime: vars.expectedSnapshotTime
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Withdraw the tokens.
        flow.withdrawAt(streamId, to, withdrawTime);

        // Assert the protocol revenue.
        assertEq(flow.protocolRevenue(token), vars.expectedProtocolRevenue, "protocol revenue");

        uint40 snapshotTime = flow.getSnapshotTime(streamId);

        // It should update snapshot time.
        assertEq(snapshotTime, vars.expectedSnapshotTime, "snapshot time");

        // It should decrease the full total debt by withdrawn amount and fee amount.
        vars.actualTotalDebt = flow.getSnapshotDebt(streamId)
            + getDenormalizedAmount({
                amount: flow.getRatePerSecond(streamId).unwrap() * (vars.expectedSnapshotTime - snapshotTime),
                decimals: flow.getTokenDecimals(streamId)
            });
        vars.expectedTotalDebt = vars.totalDebt - vars.withdrawAmount - feeAmount;
        assertEq(vars.actualTotalDebt, vars.expectedTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn amount and fee amount.
        vars.expectedStreamBalance = vars.streamBalance - vars.withdrawAmount - feeAmount;
        assertEq(flow.getBalance(streamId), vars.expectedStreamBalance, "stream balance");

        // It should reduce the token balance of stream by net withdrawn amount.
        vars.expectedTokenBalance = vars.tokenBalance - vars.withdrawAmount;
        assertEq(token.balanceOf(address(flow)), vars.expectedTokenBalance, "token balance");
    }
}
