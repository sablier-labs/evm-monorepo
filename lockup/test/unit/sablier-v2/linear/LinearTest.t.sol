// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { Amounts, Broker, Durations, LinearStream, Range } from "src/types/Structs.sol";

import { SablierV2Linear } from "src/SablierV2Linear.sol";

import { SablierV2Test } from "test/unit/sablier-v2/SablierV2.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

/// @title LinearTest
/// @notice Common testing logic needed across SablierV2Linear unit tests.
abstract contract LinearTest is SablierV2Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDurationsArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        IERC20 token;
        bool cancelable;
        Durations durations;
        Broker broker;
    }

    struct CreateWithRangeArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        IERC20 token;
        bool cancelable;
        Range range;
        Broker broker;
    }

    struct DefaultArgs {
        CreateWithDurationsArgs createWithDurations;
        CreateWithRangeArgs createWithRange;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    DefaultArgs internal defaultArgs;
    LinearStream internal defaultStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        UnitTest.setUp();

        // Create the default args to be used for the create functions.
        defaultArgs = DefaultArgs({
            createWithDurations: CreateWithDurationsArgs({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                token: dai,
                cancelable: true,
                durations: DEFAULT_DURATIONS,
                broker: Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE })
            }),
            createWithRange: CreateWithRangeArgs({
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
            isCancelable: defaultArgs.createWithRange.cancelable,
            isEntity: true,
            sender: defaultArgs.createWithRange.sender,
            range: defaultArgs.createWithRange.range,
            token: defaultArgs.createWithRange.token
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
        UD60x18 elapsedTime = UD60x18.wrap(currentTime - DEFAULT_START_TIME);
        UD60x18 totalTime = UD60x18.wrap(DEFAULT_STOP_TIME - DEFAULT_START_TIME);
        UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
        streamedAmount = uint128(UD60x18.unwrap(elapsedTimePercentage.mul(ud(depositAmount))));
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
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range,
            defaultArgs.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurations() internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            defaultArgs.createWithDurations.sender,
            defaultArgs.createWithDurations.recipient,
            defaultArgs.createWithDurations.grossDepositAmount,
            defaultArgs.createWithDurations.token,
            defaultArgs.createWithDurations.cancelable,
            defaultArgs.createWithDurations.durations,
            defaultArgs.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurations(Durations memory durations) internal returns (uint256 streamId) {
        streamId = linear.createWithDurations(
            defaultArgs.createWithDurations.sender,
            defaultArgs.createWithDurations.recipient,
            defaultArgs.createWithDurations.grossDepositAmount,
            defaultArgs.createWithDurations.token,
            defaultArgs.createWithDurations.cancelable,
            durations,
            defaultArgs.createWithDurations.broker
        );
    }

    /// @dev Creates the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            grossDepositAmount,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range,
            defaultArgs.createWithRange.broker
        );
    }

    /// @dev Creates the default stream that is non-cancelable.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.token,
            isCancelable,
            defaultArgs.createWithRange.range,
            defaultArgs.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range,
            defaultArgs.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range,
            defaultArgs.createWithRange.broker
        );
    }

    /// @dev Creates the default stream with the provided stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            Range({
                start: defaultArgs.createWithRange.range.start,
                cliff: defaultArgs.createWithRange.range.cliff,
                stop: stopTime
            }),
            defaultArgs.createWithRange.broker
        );
    }
}
