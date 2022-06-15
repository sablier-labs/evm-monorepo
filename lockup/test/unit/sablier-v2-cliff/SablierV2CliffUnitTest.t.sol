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
        uint256 indexed streamId,
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
    uint256 internal immutable WITHDRAW_AMOUNT = bn(2_600);

    /// TESTING VARIABLES ///

    SablierV2Cliff internal sablierV2Cliff = new SablierV2Cliff();
    ISablierV2Cliff.Stream internal stream;

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default stream to be used across many tests.
        stream = ISablierV2Cliff.Stream({
            cancelable: true,
            cliffTime: CLIFF_TIME,
            depositAmount: DEPOSIT_AMOUNT,
            recipient: users.recipient,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: STOP_TIME,
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Cliff contract to spend $USD from the `sender` account.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Cliff), type(uint256).max);

        // Approve the SablierV2Cliff contract to spend non-standard tokens from the `sender` account.
        vm.prank(users.sender);
        nonStandardToken.approve(address(sablierV2Cliff), type(uint256).max);

        // Approve the SablierV2Cliff contract to spend $USD from the `recipient` account.
        vm.prank(users.recipient);
        usd.approve(address(sablierV2Cliff), type(uint256).max);

        // Approve the SablierV2Cliff contract to spend $USD from the `funder` account.
        vm.prank(users.funder);
        usd.approve(address(sablierV2Cliff), type(uint256).max);

        // Approve the SablierV2Cliff contract to spend $USD from the `eve` account.
        vm.prank(users.eve);
        usd.approve(address(sablierV2Cliff), type(uint256).max);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
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

    /// @dev Helper function to create a default stream.
    function createDefaultStream() internal returns (uint256 streamId) {
        streamId = sablierV2Cliff.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.cliffTime,
            stream.stopTime,
            stream.cancelable
        );
    }
}
