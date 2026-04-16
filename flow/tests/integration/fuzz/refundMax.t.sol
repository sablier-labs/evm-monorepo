// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract RefundMax_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should refund the refundable amount of tokens from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {RefundFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple streams to refund from, each with different token decimals and rate per second.
    /// - Multiple points in time prior to depletion period.
    function testFuzz_RefundMax(
        uint256 streamId,
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

        uint128 expectedRefundableAmount = flow.refundableAmountOf(streamId);

        // It should have a non-zero refundable amount. It could be zero for a small time range upto the depletion time
        // due to precision error.
        vm.assume(expectedRefundableAmount != 0);

        // Following variables are used during assertions.
        uint256 initialAggregateAmount = flow.aggregateAmount(token);
        uint256 initialTokenBalance = token.balanceOf(address(flow));
        uint128 initialStreamBalance = flow.getBalance(streamId);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: expectedRefundableAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({
            streamId: streamId,
            sender: users.sender,
            amount: expectedRefundableAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Request the maximum refund.
        uint128 actualRefundedAmount = flow.refundMax(streamId);

        // It should update the token balance of the stream.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance - expectedRefundableAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balanceOf");

        // It should update the stored balance in the stream.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = initialStreamBalance - expectedRefundableAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should update the aggregate amount.
        uint256 actualAggregateAmount = flow.aggregateAmount(token);
        uint256 expectedAggregateAmount = initialAggregateAmount - expectedRefundableAmount;
        assertEq(actualAggregateAmount, expectedAggregateAmount, "aggregate amount");

        // It should refund the maximum refundable amount.
        assertEq(actualRefundedAmount, expectedRefundableAmount, "refunded amount");
    }
}
