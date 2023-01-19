// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { Status } from "src/types/Enums.sol";
import { Broker, Durations, LockupAmounts, LockupLinearStream, Range } from "src/types/Structs.sol";

import { Lockup_Test } from "test/unit/lockup/Lockup.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

/// @title Linear_Test
/// @notice Common testing logic needed across SablierV2LockupLinear unit tests.
abstract contract Linear_Test is Lockup_Test {
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
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupLinearStream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Unit_Test.setUp();

        // Initialize the default defaultParams to be used for the create functions.
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

        // Set the default protocol fee.
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: DEFAULT_PROTOCOL_FEE });
        comptroller.setProtocolFee({ asset: IERC20(address(nonCompliantAsset)), newProtocolFee: DEFAULT_PROTOCOL_FEE });

        // Make the sender the default caller in all subsequent tests.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function that replicates the logic of the `getStreamedAmount` function.
    function calculateStreamedAmount(
        uint40 currentTime,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime > DEFAULT_STOP_TIME) {
            return depositAmount;
        }
        unchecked {
            UD60x18 elapsedTime = ud(currentTime - DEFAULT_START_TIME);
            UD60x18 totalTime = ud(DEFAULT_TOTAL_DURATION);
            UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            streamedAmount = elapsedTimePercentage.mul(ud(depositAmount)).intoUint128();
        }
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

    /// @dev Creates the default stream with the provided stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultParams.createWithRange.sender,
            defaultParams.createWithRange.recipient,
            defaultParams.createWithRange.grossDepositAmount,
            defaultParams.createWithRange.asset,
            defaultParams.createWithRange.cancelable,
            Range({
                start: defaultParams.createWithRange.range.start,
                cliff: defaultParams.createWithRange.range.cliff,
                stop: stopTime
            }),
            defaultParams.createWithRange.broker
        );
    }
}
