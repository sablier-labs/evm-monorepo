// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";

import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

/// @title SablierV2ProUnitTest
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2ProUnitTest is SablierV2UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event CreateStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint64 startTime,
        uint64 stopTime,
        uint256[] segmentAmounts,
        SD59x18[] segmentExponents,
        uint64[] segmentMilestones,
        bool cancelable
    );

    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint256[] internal SEGMENT_AMOUNTS_DAI = [bn(2_000, 18), bn(8_000, 18)];
    uint256[] internal SEGMENT_AMOUNTS_USDC = [bn(2_000, 6), bn(8_000, 6)];
    uint64[] internal SEGMENT_DELTAS = [2_000 seconds, 8_000 seconds];
    SD59x18[] internal SEGMENT_EXPONENTS = [sd59x18(3.14e18), sd59x18(0.5e18)];
    uint64[] internal SEGMENT_MILESTONES = [2_100 seconds, 10_100 seconds];
    uint256 internal constant TIME_OFFSET = 2_000 seconds;

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Pro internal sablierV2Pro;
    ISablierV2Pro.Stream internal daiStream;
    ISablierV2Pro.Stream internal usdcStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        sablierV2Pro = new SablierV2Pro(MAX_SEGMENT_COUNT);

        // Create the default streams to be used across the tests.
        daiStream = ISablierV2Pro.Stream({
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
        usdcStream = ISablierV2Pro.Stream({
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

        // Approve the SablierV2Pro contract to spend tokens from the sender.
        vm.startPrank(users.sender);
        dai.approve(address(sablierV2Pro), UINT256_MAX);
        usdc.approve(address(sablierV2Pro), UINT256_MAX);
        nonCompliantToken.approve(address(sablierV2Pro), UINT256_MAX);

        // Approve the SablierV2Pro contract to spend tokens from the recipient.
        changePrank(users.recipient);
        dai.approve(address(sablierV2Pro), UINT256_MAX);
        usdc.approve(address(sablierV2Pro), UINT256_MAX);
        nonCompliantToken.approve(address(sablierV2Pro), UINT256_MAX);

        // Approve the SablierV2Pro contract to spend tokens from Alice.
        changePrank(users.alice);
        dai.approve(address(sablierV2Pro), UINT256_MAX);
        usdc.approve(address(sablierV2Pro), UINT256_MAX);
        nonCompliantToken.approve(address(sablierV2Pro), UINT256_MAX);

        // Approve the SablierV2Pro contract to spend tokens from Eve.
        changePrank(users.eve);
        dai.approve(address(sablierV2Pro), UINT256_MAX);
        usdc.approve(address(sablierV2Pro), UINT256_MAX);
        nonCompliantToken.approve(address(sablierV2Pro), UINT256_MAX);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to compare two `Stream` structs.
    function assertEq(ISablierV2Pro.Stream memory a, ISablierV2Pro.Stream memory b) internal {
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
