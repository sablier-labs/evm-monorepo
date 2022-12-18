// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

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
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Linear internal sablierV2Linear;
    DataTypes.LinearStream internal daiStream;
    DataTypes.LinearStream internal usdcStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        sablierV2Linear = new SablierV2Linear({ initialComptroller: sablierV2Comptroller, maxFee: MAX_FEE });

        // Create the default streams to be used across the tests.
        daiStream = DataTypes.LinearStream({
            cancelable: true,
            cliffTime: CLIFF_TIME,
            depositAmount: DEPOSIT_AMOUNT_DAI,
            isEntity: true,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: STOP_TIME,
            token: address(dai),
            withdrawnAmount: 0
        });
        usdcStream = DataTypes.LinearStream({
            cancelable: true,
            cliffTime: CLIFF_TIME,
            depositAmount: DEPOSIT_AMOUNT_USDC,
            isEntity: true,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: STOP_TIME,
            token: address(usdc),
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

    /// @dev Helper function to create a default stream with $DAI as streaming currency.
    function createDefaultDaiStream() internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.cancelable,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime
        );
    }

    /// @dev Helper function to create a default stream with $DAI as streaming currency and the provided recipient
    /// as the recipient of the stream.
    function createDefaultDaiStreamWithRecipient(address recipient) internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.cancelable,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime
        );
    }

    /// @dev Helper function to create a default stream with $DAI as streaming currency and the provided sender
    /// as the sender of the stream.
    function createDefaultDaiStreamWithSender(address sender) internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Linear.create(
            sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.cancelable,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime
        );
    }

    /// @dev Helper function to create a default stream with $USDC as streaming currency.
    function createDefaultUsdcStream() internal returns (uint256 usdcStreamId) {
        usdcStreamId = sablierV2Linear.create(
            usdcStream.sender,
            users.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.cancelable,
            usdcStream.startTime,
            usdcStream.cliffTime,
            usdcStream.stopTime
        );
    }

    /// @dev Helper function to create a non-cancelable stream with $DAI as streaming currency.
    function createNonCancelableDaiStream() internal returns (uint256 nonCancelableDaiStreamId) {
        bool cancelable = false;
        nonCancelableDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            cancelable,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime
        );
    }
}
