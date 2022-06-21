// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";
import { SablierV2Cliff } from "@sablier/v2-core/SablierV2Cliff.sol";

import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

/// @title GodModeERC20
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2CliffUnitTest is SablierV2UnitTest {
    /// EVENTS ///

    event CreateStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 cliffTime,
        uint256 stopTime,
        bool cancelable
    );

    /// CONSTANTS ///

    uint256 internal constant TIME_OFFSET = 2_600 seconds;
    uint256 internal immutable WITHDRAW_AMOUNT = bn(2_600, 18);

    /// TESTING VARIABLES ///

    SablierV2Cliff internal sablierV2Cliff = new SablierV2Cliff();
    ISablierV2Cliff.Stream internal daiStream;
    ISablierV2Cliff.Stream internal usdcStream;

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default streams to be used across the tests.
        daiStream = ISablierV2Cliff.Stream({
            cancelable: true,
            cliffTime: CLIFF_TIME,
            depositAmount: DEPOSIT_AMOUNT_DAI,
            recipient: users.recipient,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: STOP_TIME,
            token: dai,
            withdrawnAmount: 0
        });
        usdcStream = ISablierV2Cliff.Stream({
            cancelable: true,
            cliffTime: CLIFF_TIME,
            depositAmount: DEPOSIT_AMOUNT_USDC,
            recipient: users.recipient,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: STOP_TIME,
            token: usdc,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Cliff contract to spend tokens from the sender.
        vm.startPrank(users.sender);
        dai.approve(address(sablierV2Cliff), MAX_UINT_256);
        usdc.approve(address(sablierV2Cliff), MAX_UINT_256);
        nonStandardToken.approve(address(sablierV2Cliff), MAX_UINT_256);

        // Approve the SablierV2Cliff contract to spend tokens from the recipient.
        changePrank(users.recipient);
        dai.approve(address(sablierV2Cliff), MAX_UINT_256);
        usdc.approve(address(sablierV2Cliff), MAX_UINT_256);
        nonStandardToken.approve(address(sablierV2Cliff), MAX_UINT_256);

        // Approve the SablierV2Cliff contract to spend tokens from the funder.
        changePrank(users.funder);
        dai.approve(address(sablierV2Cliff), MAX_UINT_256);
        usdc.approve(address(sablierV2Cliff), MAX_UINT_256);
        nonStandardToken.approve(address(sablierV2Cliff), MAX_UINT_256);

        // Approve the SablierV2Cliff contract to spend tokens from eve.
        changePrank(users.eve);
        dai.approve(address(sablierV2Cliff), MAX_UINT_256);
        usdc.approve(address(sablierV2Cliff), MAX_UINT_256);
        nonStandardToken.approve(address(sablierV2Cliff), MAX_UINT_256);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        changePrank(users.sender);
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to compare two `Stream` structs.
    function assertEq(ISablierV2Cliff.Stream memory a, ISablierV2Cliff.Stream memory b) internal {
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.recipient, b.recipient);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.cliffTime, b.cliffTime);
        assertEq(a.stopTime, b.stopTime);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev Helper function to create a default stream with $DAI used as streaming currency.
    function createDefaultDaiStream() internal returns (uint256 daiStreamId) {
        daiStreamId = sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
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
        usdcStreamId = sablierV2Cliff.create(
            usdcStream.sender,
            usdcStream.sender,
            usdcStream.recipient,
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
        nonCancelableDaiStreamId = sablierV2Cliff.create(
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            cancelable
        );
    }
}
