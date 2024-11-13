    // SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Lockup } from "src/core/types/DataTypes.sol";
import { BatchLockup } from "src/periphery/types/DataTypes.sol";

import { ArrayBuilder } from "../../../utils/ArrayBuilder.sol";
import { BatchLockupBuilder } from "../../../utils/BatchLockupBuilder.sol";
import { Fork_Test } from "../Fork.t.sol";

/// @dev Runs against multiple fork assets.
abstract contract CreateWithTimestampsLL_BatchLockup_Fork_Test is Fork_Test {
    constructor(IERC20 asset_) Fork_Test(asset_) { }

    struct CreateWithTimestampsParams {
        uint128 batchSize;
        Lockup.Timestamps timestamps;
        uint40 cliffTime;
        address sender;
        address recipient;
        uint128 perStreamAmount;
    }

    function testForkFuzz_CreateWithTimestampsLL(CreateWithTimestampsParams memory params) external {
        params.batchSize = boundUint128(params.batchSize, 1, 20);
        params.perStreamAmount = boundUint128(params.perStreamAmount, 1, MAX_UINT128 / params.batchSize);
        params.timestamps.start =
            boundUint40(params.timestamps.start, getBlockTimestamp(), getBlockTimestamp() + 24 hours);
        params.cliffTime =
            boundUint40(params.cliffTime, params.timestamps.start + 1 seconds, params.timestamps.start + 52 weeks);
        params.timestamps.end = boundUint40(params.timestamps.end, params.cliffTime + 1 seconds, MAX_UNIX_TIMESTAMP);

        checkUsers(params.sender, params.recipient);

        uint256 firstStreamId = lockup.nextStreamId();
        uint128 totalTransferAmount = params.perStreamAmount * params.batchSize;

        deal({ token: address(FORK_ASSET), to: params.sender, give: uint256(totalTransferAmount) });
        approveContract({ asset_: FORK_ASSET, from: params.sender, spender: address(batchLockup) });

        Lockup.CreateWithTimestamps memory createParams = Lockup.CreateWithTimestamps({
            sender: params.sender,
            recipient: params.recipient,
            totalAmount: params.perStreamAmount,
            asset: FORK_ASSET,
            cancelable: true,
            transferable: true,
            timestamps: params.timestamps,
            broker: defaults.brokerNull()
        });
        BatchLockup.CreateWithTimestampsLL[] memory batchParams =
            BatchLockupBuilder.fillBatch(createParams, params.cliffTime, params.batchSize);

        // Asset flow: sender → batch → Sablier
        expectCallToTransferFrom({
            asset: FORK_ASSET,
            from: params.sender,
            to: address(batchLockup),
            value: totalTransferAmount
        });
        expectMultipleCallsToCreateWithTimestampsLL({
            count: uint64(params.batchSize),
            params: createParams,
            cliff: params.cliffTime
        });
        expectMultipleCallsToTransferFrom({
            asset: FORK_ASSET,
            count: uint64(params.batchSize),
            from: address(batchLockup),
            to: address(lockup),
            value: params.perStreamAmount
        });

        uint256[] memory actualStreamIds = batchLockup.createWithTimestampsLL(lockup, FORK_ASSET, batchParams);
        uint256[] memory expectedStreamIds = ArrayBuilder.fillStreamIds(firstStreamId, params.batchSize);
        assertEq(actualStreamIds, expectedStreamIds);
    }
}
