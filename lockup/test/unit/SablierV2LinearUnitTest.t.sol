/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SablierV2UnitTest } from "./SablierV2UnitTest.t.sol";

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";
import { SablierV2Linear } from "@sablier/v2-core/SablierV2Linear.sol";

/// @title GodModeERC20
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2LinearUnitTest is SablierV2UnitTest {
    event CreateLinearStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    );

    /// CONSTANTS ///

    uint256 internal immutable DEFAULT_DEPOSIT;
    uint256 internal constant DEFAULT_DURATION = 3600 seconds;
    uint256 internal immutable DEFAULT_START_TIME;
    uint256 internal immutable DEFAULT_STOP_TIME;
    uint256 internal immutable DEFAULT_WITHDRAW_AMOUNT;
    uint256 internal constant DEFAULT_TIME_OFFSET = 36 seconds;

    // SablierLinear-specific testing variables
    SablierV2Linear internal sablierV2Linear = new SablierV2Linear();
    ISablierV2Linear.LinearStream internal linearStream;

    /// CONSTRUCTOR ///

    constructor() {
        // Initialize the default stream values.
        DEFAULT_DEPOSIT = bn(3600);
        DEFAULT_START_TIME = block.timestamp;
        DEFAULT_STOP_TIME = block.timestamp + DEFAULT_DURATION;
        DEFAULT_WITHDRAW_AMOUNT = bn(36);
    }

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default linear stream to be used across many tests.
        linearStream = ISablierV2Linear.LinearStream({
            cancelable: true,
            depositAmount: DEFAULT_DEPOSIT,
            recipient: users.recipient,
            sender: users.sender,
            startTime: DEFAULT_START_TIME,
            stopTime: DEFAULT_STOP_TIME,
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Linear contract to spend $USD from the `sender` and the `funder`'s accounts.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Linear), type(uint256).max);

        vm.prank(users.funder);
        usd.approve(address(sablierV2Linear), type(uint256).max);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to compare two `LinearStream` structs.
    function assertEq(ISablierV2Linear.LinearStream memory a, ISablierV2Linear.LinearStream memory b) internal {
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.recipient, b.recipient);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.stopTime, b.stopTime);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev ...
    function createDefaultLinearStream() internal returns (uint256 streamId) {
        streamId = sablierV2Linear.create(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            linearStream.startTime,
            linearStream.stopTime,
            linearStream.cancelable
        );
    }
}
