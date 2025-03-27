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

        uint128 refundableAmount = flow.refundableAmountOf(streamId);

        // Ensure refundable amount is not zero. It could be zero for a small time range upto the depletion time due to
        // precision error.
        vm.assume(refundableAmount != 0);

        // Following variables are used during assertions.
        uint256 initialAggregateAmount = flow.aggregateAmount(token);
        uint256 initialTokenBalance = token.balanceOf(address(flow));
        uint128 initialStreamBalance = flow.getBalance(streamId);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: refundableAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({ streamId: streamId, sender: users.sender, amount: refundableAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // Request the maximum refund.
        flow.refundMax(streamId);

        // Assert that the token balance of stream has been updated.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance - refundableAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = initialStreamBalance - refundableAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // Assert that the aggregate amount has been updated.
        uint256 actualAggregateAmount = flow.aggregateAmount(token);
        uint256 expectedAggregateAmount = initialAggregateAmount - refundableAmount;
        assertEq(actualAggregateAmount, expectedAggregateAmount, "aggregate amount");
    }
}
