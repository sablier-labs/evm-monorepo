// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Refund_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev No refund should be allowed post depletion period.
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for refund amount.
    /// - Multiple streams to refund from, each with different asset decimals and rate per second.
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

        // Bound the time jump so that it exceeds depletion timestamp.
        uint40 depletionPeriod = flow.depletionTimeOf(streamId);
        timeJump = boundUint40(timeJump, depletionPeriod + 1, UINT40_MAX);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Expect the relevant error.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_Overrefund.selector, streamId, refundAmount, 0));

        // Request the refund.
        flow.refund(streamId, refundAmount);
    }

    /// @dev Checklist:
    /// - It should refund asset from a stream.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {RefundFromFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for refund amount, but not exceeding the refundable amount.
    /// - Multiple streams to refund from, each with different asset decimals and rate per second.
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
        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Bound the time jump to provide a realistic time frame and not exceeding depletion timestamp.
        uint40 depletionPeriod = flow.depletionTimeOf(streamId);
        timeJump = boundUint40(timeJump, getBlockTimestamp(), depletionPeriod);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: timeJump });

        // Bound the refund amount to avoid error.
        refundAmount = boundUint128(refundAmount, 0.001e18, flow.refundableAmountOf(streamId));

        // Following variables are used during assertions.
        uint256 prevAssetBalance = asset.balanceOf(address(flow));
        uint128 prevStreamBalance = flow.getBalance(streamId);
        uint128 transferAmount = getTransferAmount(refundAmount, decimals);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: streamId, sender: users.sender, refundAmount: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Request the refund.
        flow.refund(streamId, refundAmount);

        // Assert that the asset balance of stream has been updated.
        uint256 actualAssetBalance = asset.balanceOf(address(flow));
        uint256 expectedAssetBalance = prevAssetBalance - transferAmount;
        assertEq(actualAssetBalance, expectedAssetBalance, "asset balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = prevStreamBalance - refundAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
