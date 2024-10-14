// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Refund_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev No refund should be allowed post depletion period.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for refund amount.
    /// - Multiple streams to refund from, each with different token decimals and rate per second.
    /// - Multiple points in time post depletion period.
    function testFuzz_RevertWhen_PostDepletion(
        uint256 streamId,
        uint128 refundAmount,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        // Only allow non zero refund amounts.
        vm.assume(refundAmount > 0);

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so it is greater than depletion timestamp.
        uint40 depletionPeriod = uint40(flow.depletionTimeOf(streamId));
        timeJump = boundUint40(timeJump, depletionPeriod + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Expect the relevant error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_RefundOverflow.selector, streamId, refundAmount, 0));

        // Request the refund.
        flow.refund(streamId, refundAmount);
    }

    /// @dev Checklist:
    /// - It should refund token from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {RefundFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for refund amount, but not exceeding the refundable amount.
    /// - Multiple streams to refund from, each with different token decimals and rate per second.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_Refund(
        uint256 streamId,
        uint128 refundAmount,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump so that it is less than the depletion timestamp.
        uint40 depletionPeriod = uint40(flow.depletionTimeOf(streamId));
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionPeriod - 1);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Ensure refundable amount is not zero. It could be zero for a small time range upto the depletion time due to
        // precision error.
        vm.assume(flow.refundableAmountOf(streamId) != 0);

        // Bound the refund amount to avoid error.
        refundAmount = boundUint128(refundAmount, 1, flow.refundableAmountOf(streamId));

        // Following variables are used during assertions.
        uint256 initialAggregateAmount = flow.aggregateBalance(token);
        uint256 initialTokenBalance = token.balanceOf(address(flow));
        uint128 initialStreamBalance = flow.getBalance(streamId);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({ streamId: streamId, sender: users.sender, amount: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Request the refund.
        flow.refund({ streamId: streamId, amount: refundAmount });

        // Assert that the token balance of stream has been updated.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance - refundAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = initialStreamBalance - refundAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // Assert that the aggregate amount has been updated.
        uint256 actualAggregateAmount = flow.aggregateBalance(token);
        uint256 expectedAggregateAmount = initialAggregateAmount - refundAmount;
        assertEq(actualAggregateAmount, expectedAggregateAmount, "aggregate amount");
    }
}
