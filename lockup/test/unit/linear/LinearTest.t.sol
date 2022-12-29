// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { toUD60x18, ud, UD60x18, unwrap } from "@prb/math/UD60x18.sol";

import { DataTypes } from "src/types/DataTypes.sol";
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
        uint40 startTime;
        uint40 cliffTime;
        uint40 stopTime;
    }

    struct DefaultArgs {
        CreateWithDurationArgs createWithDuration;
        CreateWithRangeArgs createWithRange;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    DefaultArgs internal defaultArgs;
    DataTypes.LinearStream internal defaultStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

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
                startTime: DEFAULT_START_TIME,
                cliffTime: DEFAULT_CLIFF_TIME,
                stopTime: DEFAULT_STOP_TIME
            })
        });

        // Create the default streams to be used across the tests.
        defaultStream = DataTypes.LinearStream({
            cliffTime: defaultArgs.createWithRange.cliffTime,
            depositAmount: DEFAULT_NET_DEPOSIT_AMOUNT,
            isCancelable: defaultArgs.createWithRange.cancelable,
            isEntity: true,
            sender: defaultArgs.createWithRange.sender,
            startTime: defaultArgs.createWithRange.startTime,
            stopTime: defaultArgs.createWithRange.stopTime,
            token: defaultArgs.createWithRange.token,
            withdrawnAmount: 0
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
        UD60x18 elapsedTime = toUD60x18(currentTime - defaultStream.startTime);
        UD60x18 totalTime = toUD60x18(defaultStream.stopTime - defaultStream.startTime);
        UD60x18 elapsedTimePercentage = elapsedTime.div(totalTime);
        streamedAmount = uint128(unwrap(elapsedTimePercentage.mul(ud(depositAmount))));
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to create the default stream.
    function createDefaultStream() internal returns (uint256 defaultStreamId) {
        defaultStreamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    /// @dev Helper function to create a default stream that is non-cancelable.
    function createDefaultStreamNonCancelable() internal returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            isCancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    /// @dev Helper function to create a default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    /// @dev Helper function to create a default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    /// @dev Helper function to create a default stream with the provided stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal returns (uint256 streamId) {
        streamId = linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            defaultArgs.createWithRange.cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            stopTime
        );
    }
}
