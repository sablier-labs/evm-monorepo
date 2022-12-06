// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

/// @title SablierV2LinearTest
/// @notice Common contract members needed across SablierV2Linear integration tests
abstract contract SablierV2LinearTest is IntegrationTest {
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
        sablierV2Linear = new SablierV2Linear();

        // Create the default streams to be used across the tests.
        daiStream = DataTypes.LinearStream({
            cancelable: true,
            cliffTime: CLIFF_TIME,
            depositAmount: DEPOSIT_AMOUNT_DAI,
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

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to create a default stream with $DAI used as streaming currency.
    function createDefaultDaiStream() internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );
    }

    /// @dev Helper function to create a default stream with $USDC used as streaming currency.
    function createDefaultUsdcStream() internal returns (uint256 usdcStreamId) {
        usdcStreamId = sablierV2Linear.create(
            usdcStream.sender,
            users.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.cliffTime,
            usdcStream.stopTime,
            usdcStream.cancelable
        );
    }

    /// @dev Helper function to create a non-cancelable stream with $DAI used as streaming currency.
    function createNonCancelableDaiStream() internal returns (uint256 nonCancelableDaiStreamId) {
        bool cancelable = false;
        nonCancelableDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            cancelable
        );
    }
}
