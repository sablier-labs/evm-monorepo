// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Status } from "src/types/Enums.sol";
import { Broker, Durations, LockupLinearStream, Range } from "src/types/Structs.sol";

import { Lockup_Shared_Test } from "test/shared/lockup/Lockup.t.sol";

/// @title Linear_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupLinear} unit and fuzz tests.
abstract contract Linear_Shared_Test is Lockup_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDurationsParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        IERC20 asset;
        bool cancelable;
        Durations durations;
        Broker broker;
    }

    struct CreateWithRangeParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        IERC20 asset;
        bool cancelable;
        Range range;
        Broker broker;
    }

    struct DefaultParams {
        CreateWithDurationsParams createWithDurations;
        CreateWithRangeParams createWithRange;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinearStream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Shared_Test.setUp();

        // Initialize the default params to be used for the create functions.
        defaultParams = DefaultParams({
            createWithDurations: CreateWithDurationsParams({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                asset: DEFAULT_ASSET,
                cancelable: true,
                durations: DEFAULT_DURATIONS,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            }),
            createWithRange: CreateWithRangeParams({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                asset: DEFAULT_ASSET,
                cancelable: true,
                range: DEFAULT_RANGE,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            })
        });

        // Create the default stream to be used across the tests.
        defaultStream = LockupLinearStream({
            amounts: DEFAULT_LOCKUP_AMOUNTS,
            isCancelable: defaultParams.createWithRange.cancelable,
            sender: defaultParams.createWithRange.sender,
            status: Status.ACTIVE,
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
            defaultParams.createWithRange.grossDepositAmount,
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
            defaultParams.createWithDurations.grossDepositAmount,
            defaultParams.createWithDurations.asset,
            defaultParams.createWithDurations.cancelable,
            defaultParams.createWithDurations.durations,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurations(Durations memory durations) internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            defaultParams.createWithDurations.sender,
            defaultParams.createWithDurations.recipient,
            defaultParams.createWithDurations.grossDepositAmount,
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
            defaultParams.createWithRange.grossDepositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            Range({
                start: defaultParams.createWithRange.range.start,
                cliff: defaultParams.createWithRange.range.cliff,
                end: endTime
            }),
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            grossDepositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }

    /// @dev Creates the default stream that is non-cancelable.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.grossDepositAmount,
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
            defaultParams.createWithRange.grossDepositAmount,
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
            defaultParams.createWithRange.grossDepositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            defaultParams.createWithRange.range,
            defaultParams.createWithRange.broker
        );
    }
}
