/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SablierV2UnitTest } from "./SablierV2UnitTest.t.sol";

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";
import { SablierV2Cliff } from "@sablier/v2-core/SablierV2Cliff.sol";

/// @title GodModeERC20
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2CliffUnitTest is SablierV2UnitTest {
    /// EVENTS ///

    event CreateCliffStream(
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

    uint256 internal constant DEFAULT_CLIFF_DURATION = 900 seconds;
    uint256 internal constant DEFAULT_TOTAL_DURATION = 3600 seconds;
    uint256 internal constant DEFAULT_TIME_OFFSET = 900 seconds;

    uint256 internal immutable DEFAULT_DEPOSIT;
    uint256 internal immutable DEFAULT_START_TIME;
    uint256 internal immutable DEFAULT_STOP_TIME;
    uint256 internal immutable DEFAULT_CLIFF_TIME;
    uint256 internal immutable DEFAULT_WITHDRAW_AMOUNT;

    /// CLIFF-SPECIFIC TESTING VARIABLES ///

    SablierV2Cliff internal sablierV2Cliff = new SablierV2Cliff();
    ISablierV2Cliff.CliffStream internal cliffStream;

    /// CONSTRUCTOR ///

    constructor() {
        // Initialize the default stream values.
        DEFAULT_CLIFF_TIME = block.timestamp + DEFAULT_TIME_OFFSET;
        DEFAULT_DEPOSIT = bn(3600);
        DEFAULT_START_TIME = block.timestamp;
        DEFAULT_STOP_TIME = block.timestamp + DEFAULT_TOTAL_DURATION;
        DEFAULT_WITHDRAW_AMOUNT = bn(900);
    }

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default cliff stream to be used across many tests.
        cliffStream = ISablierV2Cliff.CliffStream({
            cancelable: true,
            cliffTime: DEFAULT_CLIFF_TIME,
            depositAmount: DEFAULT_DEPOSIT,
            recipient: users.recipient,
            sender: users.sender,
            startTime: DEFAULT_START_TIME,
            stopTime: DEFAULT_STOP_TIME,
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Cliff contract to spend $USD from the `sender` and the `funder`'s accounts.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Cliff), type(uint256).max);

        vm.prank(users.funder);
        usd.approve(address(sablierV2Cliff), type(uint256).max);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to compare two `CliffStream` structs.
    function assertEq(ISablierV2Cliff.CliffStream memory a, ISablierV2Cliff.CliffStream memory b) internal {
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.recipient, b.recipient);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.cliffTime, b.cliffTime);
        // assertEq(a.stopTime, b.stopTime);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev Helper function to create a default cliff stream.
    function createDefaultCliffStream() internal returns (uint256 streamId) {
        streamId = sablierV2Cliff.create(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            cliffStream.startTime,
            cliffStream.cliffTime,
            cliffStream.stopTime,
            cliffStream.cancelable
        );
    }
}
