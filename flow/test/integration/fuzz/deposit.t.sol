// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Deposit_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should deposit asset into a stream. 40% runs should load streams from fixtures.
    /// - It should emit the following events:
    ///   - {Transfer}
    ///   - {MetadataUpdate}
    ///   - {DepositFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for funders.
    /// - Multiple non-zero values for transfer amount.
    /// - Multiple streams to deposit into, each with different asset decimals. Some of them would have amount deposited
    /// previously and some of them would be fresh.
    /// - Multiple points in time to deposit into the stream.
    function testFuzz_Deposit(
        uint256 streamId,
        address funder,
        uint128 transferAmount,
        uint8 decimals,
        uint40 timeJump
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        vm.assume(funder != address(0) && funder != address(flow) && streamId > 0);

        IERC20 asset;

        // Check if stream id is picked from the fixtures.
        if (!flow.isStream(streamId)) {
            // If not, create a new stream.
            decimals = boundUint8(decimals, 0, 18);
            asset = createAsset(decimals);
            streamId = createDefaultStreamWithAsset(asset);
        } else {
            decimals = flow.getAssetDecimals(streamId);
            asset = flow.getAsset(streamId);
        }

        // Bound the transfer amount to avoid overflow.
        transferAmount = boundTransferAmount(transferAmount, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 1 seconds, 100 weeks);

        // Change prank to funder and deal some tokens to him.
        deal({ token: address(asset), to: funder, give: transferAmount });
        resetPrank(funder);

        // Approve the flow contract to spend the asset.
        asset.approve(address(flow), transferAmount);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Following variables are used during assertions.
        uint256 prevAssetBalance = asset.balanceOf(address(flow));
        uint128 prevStreamBalance = flow.getBalance(streamId);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: funder, to: address(flow), value: transferAmount });

        uint128 normalizedAmount = getNormalizedAmount(transferAmount, decimals);

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: funder, asset: asset, depositAmount: normalizedAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC20 transfer.
        expectCallToTransferFrom({ asset: asset, from: funder, to: address(flow), amount: transferAmount });

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
