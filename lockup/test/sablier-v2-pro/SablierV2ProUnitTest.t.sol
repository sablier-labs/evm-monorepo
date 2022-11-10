// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";

import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

/// @title SablierV2ProUnitTest
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2ProUnitTest is SablierV2UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint256[] internal SEGMENT_AMOUNTS_DAI = [2_000e18, 8_000e18];
    uint256[] internal SEGMENT_AMOUNTS_USDC = [2_000e6, 8_000e6];
    uint64[] internal SEGMENT_DELTAS = [2_000 seconds, 8_000 seconds];
    SD59x18[] internal SEGMENT_EXPONENTS = [sd59x18(3.14e18), sd59x18(0.5e18)];
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
            token: dai,
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
            token: usdc,
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

    /// @dev Helper function to compare two `Stream` structs.
    function assertEq(DataTypes.ProStream memory a, DataTypes.ProStream memory b) internal {
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.sender, b.sender);
        assertEq(uint256(a.startTime), uint256(b.startTime));
        assertEq(uint256(a.stopTime), uint256(b.stopTime));
        assertEq(a.segmentAmounts, b.segmentAmounts);
        assertEq(a.segmentExponents, b.segmentExponents);
        assertEqUint64Array(a.segmentMilestones, b.segmentMilestones);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev Helper function to compare two SD59x18 arrays.
    function assertEq(SD59x18[] memory a, SD59x18[] memory b) internal {
        int256[] memory castedA;
        int256[] memory castedB;
        assembly {
            castedA := a
            castedB := b
        }
        assertEq(castedA, castedB);
    }

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
