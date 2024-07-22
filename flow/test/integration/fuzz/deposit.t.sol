// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Deposit_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should deposit asset into a stream. 40% runs should load streams from fixtures.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {DepositFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for callers.
    /// - Multiple non-zero values for transfer amount.
    /// - Multiple streams to deposit into, each with different asset decimals and rps.
    /// - Multiple points in time.
    function testFuzz_Deposit(
        address caller,
        uint256 streamId,
        uint128 transferAmount,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        vm.assume(caller != address(0) && caller != address(flow));

        (streamId, decimals,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Following variables are used during assertions.
        uint256 prevAssetBalance = asset.balanceOf(address(flow));
        uint128 prevStreamBalance = flow.getBalance(streamId);

        // Bound the transfer amount to avoid overflow.
        transferAmount = boundTransferAmount(transferAmount, prevStreamBalance, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        // Change prank to caller and deal some tokens to him.
        deal({ token: address(asset), to: caller, give: transferAmount });
        resetPrank(caller);

        // Approve the flow contract to spend the asset.
        asset.approve(address(flow), transferAmount);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: caller, to: address(flow), value: transferAmount });

        uint128 normalizedAmount = getNormalizedAmount(transferAmount, decimals);

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: caller, depositAmount: normalizedAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC20 transfer.
        expectCallToTransferFrom({ asset: asset, from: caller, to: address(flow), amount: transferAmount });

        // Make the deposit.
        flow.deposit(streamId, transferAmount);

        // Assert that the asset balance of stream has been updated.
        uint256 actualAssetBalance = asset.balanceOf(address(flow));
        uint256 expectedAssetBalance = prevAssetBalance + transferAmount;
        assertEq(actualAssetBalance, expectedAssetBalance, "asset balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = prevStreamBalance + normalizedAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
