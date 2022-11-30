// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { sd, SD59x18 } from "@prb/math/SD59x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { IntegrationTest } from "../IntegrationTest.t.sol";

/// @title SablierV2ProTest
/// @notice Common contract members needed across SablierV2Pro integration test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2ProTest is IntegrationTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256[] internal SEGMENT_AMOUNTS_DAI = [2_000e18, 8_000e18];
    uint256[] internal SEGMENT_AMOUNTS_USDC = [2_000e6, 8_000e6];
    uint64[] internal SEGMENT_DELTAS = [2_000 seconds, 8_000 seconds];
    SD59x18[] internal SEGMENT_EXPONENTS = [sd(3.14e18), sd(0.5e18)];
    uint64[] internal SEGMENT_MILESTONES = [2_100 seconds, 10_100 seconds];
    uint256 internal constant TIME_OFFSET = 2_000 seconds;

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Pro internal sablierV2Pro;
    DataTypes.ProStream internal daiStream;
    DataTypes.ProStream internal usdcStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        sablierV2Pro = new SablierV2Pro(MAX_SEGMENT_COUNT);

        // Create the default streams to be used across the tests.
        daiStream = DataTypes.ProStream({
            cancelable: true,
            depositAmount: DEPOSIT_AMOUNT_DAI,
            segmentAmounts: SEGMENT_AMOUNTS_DAI,
            segmentExponents: SEGMENT_EXPONENTS,
            segmentMilestones: SEGMENT_MILESTONES,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: SEGMENT_MILESTONES[1],
            token: address(dai),
            withdrawnAmount: 0
        });
        usdcStream = DataTypes.ProStream({
            cancelable: true,
            depositAmount: DEPOSIT_AMOUNT_USDC,
            segmentAmounts: SEGMENT_AMOUNTS_USDC,
            segmentExponents: SEGMENT_EXPONENTS,
            segmentMilestones: SEGMENT_MILESTONES,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: SEGMENT_MILESTONES[1],
            token: address(usdc),
            withdrawnAmount: 0
        });

        // Approve the SablierV2Pro contract to spend tokens from the sender, recipient, Alice and Eve.
        approveMax(users.sender, address(sablierV2Pro));
        approveMax(users.recipient, address(sablierV2Pro));
        approveMax(users.alice, address(sablierV2Pro));
        approveMax(users.eve, address(sablierV2Pro));

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to create a default stream with $DAI used as streaming currency.
    function createDefaultDaiStream() internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev Helper function to create a default stream with $USDC used as streaming currency.
    function createDefaultUsdcStream() internal returns (uint256 usdcStreamId) {
        usdcStreamId = sablierV2Pro.create(
            usdcStream.sender,
            users.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.segmentAmounts,
            usdcStream.segmentExponents,
            usdcStream.segmentMilestones,
            usdcStream.cancelable
        );
    }

    /// @dev Helper function to create a non-cancelable stream.
    function createNonCancelableDaiStream() internal returns (uint256 nonCancelableDaiStreamId) {
        bool cancelable = false;
        nonCancelableDaiStreamId = sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            cancelable
        );
    }
}
