// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { Amounts, LinearStream, Range } from "src/types/Structs.sol";

import { SablierV2Linear } from "src/SablierV2Linear.sol";

import { UnitTest } from "../UnitTest.t.sol";

/// @title LinearTest
/// @notice Common contract members needed across SablierV2Linear unit tests.
abstract contract LinearTest is UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDurationArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        address operator;
        UD60x18 operatorFee;
        address token;
        bool cancelable;
        uint40 cliffDuration;
        uint40 totalDuration;
    }

    struct CreateWithRangeArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        address operator;
        UD60x18 operatorFee;
        address token;
        bool cancelable;
        Range range;
    }

    struct DefaultArgs {
        CreateWithDurationArgs createWithDuration;
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
            createWithDuration: CreateWithDurationArgs({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                operator: users.operator,
                operatorFee: DEFAULT_OPERATOR_FEE,
                token: address(dai),
                cancelable: true,
                cliffDuration: DEFAULT_CLIFF_DURATION,
                totalDuration: DEFAULT_TOTAL_DURATION
            }),
            createWithRange: CreateWithRangeArgs({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                operator: users.operator,
                operatorFee: DEFAULT_OPERATOR_FEE,
                token: address(dai),
                cancelable: true,
                range: DEFAULT_RANGE
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
        comptroller.setProtocolFee(address(dai), DEFAULT_PROTOCOL_FEE);
        comptroller.setProtocolFee(address(nonCompliantToken), DEFAULT_PROTOCOL_FEE);

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
        UD60x18 elapsedTime = UD60x18.wrap(currentTime - defaultStream.range.start);
        UD60x18 totalTime = UD60x18.wrap(defaultStream.range.stop - defaultStream.range.start);
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

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range
        );
    }

    /// @dev Creates the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range
        );
    }

    /// @dev Creates the default stream that is non-cancelable.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            isCancelable,
            defaultArgs.createWithRange.range
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = linear.createWithRange(
            sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.range
        );
    }

    /// @dev Creates the default stream with the provided stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            Range({
                start: defaultArgs.createWithRange.range.start,
                cliff: defaultArgs.createWithRange.range.cliff,
                stop: stopTime
            })
        );
    }
}
