/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2UnitTest } from "../SablierV2UnitTest.t.sol";

/// @title SablierV2ProUnitTest
/// @author Sablier Labs Ltd.
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract SablierV2ProUnitTest is SablierV2UnitTest {
    /// EVENTS ///

    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256 stopTime,
        uint256[] segmentAmounts,
        SD59x18[] segmentExponents,
        uint256[] segmentMilestones,
        bool cancelable
    );

    /// CONSTANTS ///

    uint256[] internal DEFAULT_SEGMENT_AMOUNTS = [bn(2_500), bn(7_500)];
    SD59x18[] internal DEFAULT_SEGMENT_EXPONENTS = [sd59x18(1), sd59x18(2)];
    uint256[] internal DEFAULT_SEGMENT_MILESTONES = [5_100 seconds, 10_100 seconds];
    uint256 internal constant DEFAULT_TIME_OFFSET = 5_000 seconds;
    uint256 internal immutable DEFAULT_WITHDRAW_AMOUNT = bn(2_500);
    SD59x18 internal constant MAX_EXPONENT = SD59x18.wrap(10e18);

    /// TESTING VARIABLES ///

    SablierV2Pro internal sablierV2Pro = new SablierV2Pro();
    ISablierV2Pro.Stream internal stream;

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default stream to be used across many tests.
        stream = ISablierV2Pro.Stream({
            cancelable: true,
            depositAmount: DEFAULT_DEPOSIT_AMOUNT,
            recipient: users.recipient,
            segmentAmounts: DEFAULT_SEGMENT_AMOUNTS,
            segmentExponents: DEFAULT_SEGMENT_EXPONENTS,
            segmentMilestones: DEFAULT_SEGMENT_MILESTONES,
            sender: users.sender,
            startTime: DEFAULT_START_TIME,
            stopTime: DEFAULT_STOP_TIME,
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Pro contract to spend $USD from the `sender` account.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Pro), type(uint256).max);

        // Approve the SablierV2Pro contract to spend $USD from the `funder` account.
        vm.prank(users.funder);
        usd.approve(address(sablierV2Pro), type(uint256).max);

        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }

    /// NON-CONSTANT FUNCTIONS ///

    /// @dev Helper function to compare two `Stream` structs.
    function assertEq(ISablierV2Pro.Stream memory a, ISablierV2Pro.Stream memory b) internal {
        assertEq(a.depositAmount, b.depositAmount);
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.recipient, b.recipient);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.stopTime, b.stopTime);
        assertEq(a.segmentAmounts, b.segmentAmounts);
        assertEq(a.segmentExponents, b.segmentExponents);
        assertEq(a.segmentMilestones, b.segmentMilestones);
        assertEq(a.token, b.token);
        assertEq(a.withdrawnAmount, b.withdrawnAmount);
    }

    /// @dev Helper function to compare two uint256 arrays.
    function assertEq(uint256[] memory a, uint256[] memory b) internal {
        if (a.length != b.length) {
            emit log("Error: a.length == b.length not satisifed");
            fail();
        }

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i]);
        }
    }

    /// @dev Helper function to compare two SD59x18 arrays.
    function assertEq(SD59x18[] memory a, SD59x18[] memory b) internal {
        if (a.length != b.length) {
            emit log("Error: a.length == b.length not satisifed");
            fail();
        }

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(SD59x18.unwrap(a[i]), SD59x18.unwrap(b[i]));
        }
    }

    /// @dev Helper function to create a pro stream.
    function createDefaultStream() internal returns (uint256 streamId) {
        streamId = sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }
}
