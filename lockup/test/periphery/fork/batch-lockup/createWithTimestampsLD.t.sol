// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BatchLockup, Lockup, LockupDynamic } from "src/core/types/DataTypes.sol";

import { ArrayBuilder } from "../../../utils/ArrayBuilder.sol";
import { BatchLockupBuilder } from "../../../utils/BatchLockupBuilder.sol";
import { Fork_Test } from "../Fork.t.sol";

/// @dev Runs against multiple fork assets.
abstract contract CreateWithTimestampsLD_BatchLockup_Fork_Test is Fork_Test {
    constructor(IERC20 asset_) Fork_Test(asset_) { }

    struct CreateWithTimestampsParams {
        uint128 batchSize;
        address sender;
        address recipient;
        uint128 perStreamAmount;
        uint40 startTime;
        LockupDynamic.Segment[] segments;
    }

    function testForkFuzz_CreateWithTimestampsLD(CreateWithTimestampsParams memory params) external {
        vm.assume(params.segments.length != 0);
        params.batchSize = boundUint128(params.batchSize, 1, 20);
        params.startTime = boundUint40(params.startTime, getBlockTimestamp(), getBlockTimestamp() + 24 hours);
        fuzzSegmentTimestamps(params.segments, params.startTime);
        (params.perStreamAmount,) = fuzzDynamicStreamAmounts({
            upperBound: MAX_UINT128 / params.batchSize,
            segments: params.segments,
            brokerFee: defaults.brokerNull().fee
        });

        checkUsers(params.sender, params.recipient);

        uint256 firstStreamId = lockup.nextStreamId();
        uint128 totalTransferAmount = params.perStreamAmount * params.batchSize;

        deal({ token: address(FORK_ASSET), to: params.sender, give: uint256(totalTransferAmount) });
        approveContract({ asset_: FORK_ASSET, from: params.sender, spender: address(batchLockup) });

        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: params.startTime, end: params.segments[params.segments.length - 1].timestamp });

        Lockup.CreateWithTimestamps memory createWithTimestamps = Lockup.CreateWithTimestamps({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: params.perStreamAmount,
            asset: FORK_ASSET,
            cancelable: true,
            transferable: true,
            timestamps: timestamps,
            broker: defaults.brokerNull()
        });

        BatchLockup.CreateWithTimestampsLD[] memory batchParams =
            BatchLockupBuilder.fillBatch(createWithTimestamps, params.segments, params.batchSize);

        expectCallToTransferFrom({
            asset: FORK_ASSET,
            from: params.sender,
            to: address(batchLockup),
            value: totalTransferAmount
        });
        expectMultipleCallsToCreateWithTimestampsLD({
            count: uint64(params.batchSize),
            params: createWithTimestamps,
            segments: params.segments
        });
        expectMultipleCallsToTransferFrom({
            asset: FORK_ASSET,
            count: uint64(params.batchSize),
            from: address(batchLockup),
            to: address(lockup),
            value: params.perStreamAmount
        });

        uint256[] memory actualStreamIds = batchLockup.createWithTimestampsLD(lockup, FORK_ASSET, batchParams);
        uint256[] memory expectedStreamIds = ArrayBuilder.fillStreamIds(firstStreamId, params.batchSize);
        assertEq(actualStreamIds, expectedStreamIds);
    }
}
