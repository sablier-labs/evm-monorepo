// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, Lockup, LockupLinear } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../Lockup.t.sol";

/// @title Linear_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupLinear} unit and fuzz tests.
abstract contract Linear_Shared_Test is Lockup_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDurationsParams {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        LockupLinear.Durations durations;
        Broker broker;
    }

    struct CreateWithRangeParams {
        address sender;
        address recipient;
        uint128 totalAmount;
        IERC20 asset;
        bool cancelable;
        LockupLinear.Range range;
        Broker broker;
    }

    struct DefaultParams {
        CreateWithDurationsParams createWithDurations;
        CreateWithRangeParams createWithRange;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinear.Stream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Shared_Test.setUp();

        // Initialize the default params to be used for the create functions.
        defaultParams = DefaultParams({
            createWithDurations: CreateWithDurationsParams({
                sender: users.sender,
                recipient: users.recipient,
                totalAmount: DEFAULT_TOTAL_AMOUNT,
                asset: DEFAULT_ASSET,
                cancelable: true,
                durations: DEFAULT_DURATIONS,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            }),
            createWithRange: CreateWithRangeParams({
                sender: users.sender,
                recipient: users.recipient,
                totalAmount: DEFAULT_TOTAL_AMOUNT,
                asset: DEFAULT_ASSET,
                cancelable: true,
                range: DEFAULT_LINEAR_RANGE,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            })
        });

        // Create the default stream to be used across the tests.
        defaultStream = LockupLinear.Stream({
            amounts: DEFAULT_LOCKUP_AMOUNTS,
            isCancelable: defaultParams.createWithRange.cancelable,
            sender: defaultParams.createWithRange.sender,
            status: Lockup.Status.ACTIVE,
            range: defaultParams.createWithRange.range,
            asset: defaultParams.createWithRange.asset
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurations() internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            defaultParams.createWithDurations.sender,
            defaultParams.createWithDurations.recipient,
            defaultParams.createWithDurations.totalAmount,
            defaultParams.createWithDurations.asset,
            defaultParams.createWithDurations.cancelable,
            defaultParams.createWithDurations.durations,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurations(
        LockupLinear.Durations memory durations
    ) internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            defaultParams.createWithDurations.sender,
            defaultParams.createWithDurations.recipient,
            defaultParams.createWithDurations.totalAmount,
            defaultParams.createWithDurations.asset,
            defaultParams.createWithDurations.cancelable,
            durations,
            defaultParams.createWithDurations.broker
        );
    }

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            LockupLinear.Range({
                start: defaultParams.createWithRange.range.start,
                cliff: defaultParams.createWithRange.range.cliff,
                end: endTime
            }),
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream that is non-cancelable.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            isCancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            totalAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }
}
