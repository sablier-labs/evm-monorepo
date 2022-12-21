// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ERC20 } from "@prb/contracts/token/erc20/ERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";

import { UnitTest } from "../UnitTest.t.sol";

/// @title SablierV2LinearTest
/// @notice Common contract members needed across SablierV2Linear unit tests.
abstract contract SablierV2LinearTest is UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint40 internal constant TIME_OFFSET = 2_600 seconds;
    uint128 internal immutable WITHDRAW_AMOUNT_DAI = 2_600e18;
    uint128 internal immutable WITHDRAW_AMOUNT_USDC = 2_600e6;

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

    SablierV2Linear internal sablierV2Linear;
    DefaultArgs internal defaultArgs;
    DataTypes.LinearStream internal defaultStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        sablierV2Linear = new SablierV2Linear({ initialComptroller: sablierV2Comptroller, maxFee: MAX_FEE });

        // Create the default args to be used across the tests.
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
            cancelable: defaultArgs.createWithRange.cancelable,
            cliffTime: defaultArgs.createWithRange.cliffTime,
            depositAmount: DEFAULT_NET_DEPOSIT_AMOUNT,
            isEntity: true,
            sender: defaultArgs.createWithRange.sender,
            startTime: defaultArgs.createWithRange.startTime,
            stopTime: defaultArgs.createWithRange.stopTime,
            token: defaultArgs.createWithRange.token,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Linear contract to spend tokens from the sender, recipient, Alice and Eve.
        approveMax({ caller: users.sender, spender: address(sablierV2Linear) });
        approveMax({ caller: users.recipient, spender: address(sablierV2Linear) });
        approveMax({ caller: users.alice, spender: address(sablierV2Linear) });
        approveMax({ caller: users.eve, spender: address(sablierV2Linear) });

        // Make the sender the caller for all subsequent calls.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to create the default stream.
    function createDefaultStream() internal returns (uint256 defaultStreamId) {
        defaultStreamId = sablierV2Linear.createWithRange(
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
    function createDefaultStreamNonCancelable() internal returns (uint256 nonCancelableDefaultStreamId) {
        bool cancelable = false;
        nonCancelableDefaultStreamId = sablierV2Linear.createWithRange(
            defaultArgs.createWithRange.sender,
            defaultArgs.createWithRange.recipient,
            defaultArgs.createWithRange.grossDepositAmount,
            defaultArgs.createWithRange.operator,
            defaultArgs.createWithRange.operatorFee,
            defaultArgs.createWithRange.token,
            cancelable,
            defaultArgs.createWithRange.startTime,
            defaultArgs.createWithRange.cliffTime,
            defaultArgs.createWithRange.stopTime
        );
    }

    /// @dev Helper function to create a default stream and the provided recipient as the recipient of the stream.
    function createDefaultStreamWithRecipient(address recipient) internal returns (uint256 defaultStreamId) {
        defaultStreamId = sablierV2Linear.createWithRange(
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

    /// @dev Helper function to create a default stream and the provided sender as the sender of the stream.
    function createDefaultDaiStreamWithSender(address sender) internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Linear.createWithRange(
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
}
