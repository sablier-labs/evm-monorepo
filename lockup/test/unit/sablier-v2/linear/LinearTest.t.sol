// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ud, UD60x18, unwrap } from "@prb/math/UD60x18.sol";

import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { Amounts, Broker, Durations, LinearStream, Range } from "src/types/Structs.sol";

import { SablierV2Test } from "test/unit/sablier-v2/SablierV2.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

/// @title LinearTest
/// @notice Common testing logic needed across SablierV2Linear unit tests.
abstract contract LinearTest is SablierV2Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDurationsParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        IERC20 token;
        bool cancelable;
        Durations durations;
        Broker broker;
    }

    struct CreateWithRangeParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        IERC20 token;
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

    LinearStream internal defaultStream;
    DefaultParams internal params;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        UnitTest.setUp();

        // Initialize the default params to be used for the create functions.
        params = DefaultParams({
            createWithDurations: CreateWithDurationsParams({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                token: dai,
                cancelable: true,
                durations: DEFAULT_DURATIONS,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            }),
            createWithRange: CreateWithRangeParams({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                token: dai,
                cancelable: true,
                range: DEFAULT_RANGE,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            })
        });

        // Create the default stream to be used across the tests.
        defaultStream = LinearStream({
            amounts: DEFAULT_AMOUNTS,
            isCancelable: params.createWithRange.cancelable,
            isEntity: true,
            sender: params.createWithRange.sender,
            range: params.createWithRange.range,
            token: params.createWithRange.token
        });

        // Set the default protocol fee.
        comptroller.setProtocolFee(dai, DEFAULT_PROTOCOL_FEE);
        comptroller.setProtocolFee(IERC20(address(nonCompliantToken)), DEFAULT_PROTOCOL_FEE);

        // Make the sender the default caller in all subsequent tests.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function that replicates the logic of the `getWithdrawableAmount` function, but which
    /// does not subtract the withdrawn amount.
    function calculateStreamedAmount(
        uint40 currentTime,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        UD60x18 elapsedTime = ud(currentTime - DEFAULT_START_TIME);
        UD60x18 totalTime = ud(DEFAULT_STOP_TIME - DEFAULT_START_TIME);
        UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
        streamedAmount = uint128(unwrap(elapsedTimePercentage.mul(ud(depositAmount))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that the given stream was deleted.
    function assertDeleted(uint256 streamId) internal override {
        LinearStream memory deletedStream = linear.getStream(streamId);
        LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev Checks that the given streams were deleted.
    function assertDeleted(uint256[] memory streamIds) internal override {
        for (uint256 i = 0; i < streamIds.length; ++i) {
            LinearStream memory deletedStream = linear.getStream(streamIds[i]);
            LinearStream memory expectedStream;
            assertEq(deletedStream, expectedStream);
        }
    }

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurations() internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            params.createWithDurations.sender,
            params.createWithDurations.recipient,
            params.createWithDurations.grossDepositAmount,
            params.createWithDurations.token,
            params.createWithDurations.cancelable,
            params.createWithDurations.durations,
            params.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurations(Durations memory durations) internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            params.createWithDurations.sender,
            params.createWithDurations.recipient,
            params.createWithDurations.grossDepositAmount,
            params.createWithDurations.token,
            params.createWithDurations.cancelable,
            durations,
            params.createWithDurations.broker
        );
    }

    /// @dev Creates the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );
    }

    /// @dev Creates the default stream that is non-cancelable.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            isCancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            params.createWithRange.sender,
            recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            params.createWithRange.range,
            params.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            params.createWithRange.sender,
            params.createWithRange.recipient,
            params.createWithRange.grossDepositAmount,
            params.createWithRange.token,
            params.createWithRange.cancelable,
            Range({
                start: params.createWithRange.range.start,
                cliff: params.createWithRange.range.cliff,
                stop: stopTime
            }),
            params.createWithRange.broker
        );
    }
}
