// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";

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
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        uint256[] segmentAmounts,
        SD59x18[] segmentExponents,
        uint256[] segmentMilestones,
        bool cancelable
    );

    /// CONSTANTS ///

    uint256 internal constant MAX_SEGMENT_COUNT = 200;
    uint256[] internal SEGMENT_AMOUNTS = [bn(2_000), bn(8_000)];
    SD59x18[] internal SEGMENT_EXPONENTS = [sd59x18(3.14e18), sd59x18(0.5e18)];
    uint256[] internal SEGMENT_MILESTONES = [2_100 seconds, 10_100 seconds];
    uint256 internal constant TIME_OFFSET = 2_000 seconds;

    /// TESTING VARIABLES ///

    SablierV2Pro internal sablierV2Pro = new SablierV2Pro(MAX_SEGMENT_COUNT);
    ISablierV2Pro.Stream internal stream;

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Create the default stream to be used across many tests.
        stream = ISablierV2Pro.Stream({
            cancelable: true,
            depositAmount: DEPOSIT_AMOUNT,
            recipient: users.recipient,
            segmentAmounts: SEGMENT_AMOUNTS,
            segmentExponents: SEGMENT_EXPONENTS,
            segmentMilestones: SEGMENT_MILESTONES,
            sender: users.sender,
            startTime: START_TIME,
            stopTime: SEGMENT_MILESTONES[1],
            token: usd,
            withdrawnAmount: 0
        });

        // Approve the SablierV2Pro contract to spend $USD from the `sender` account.
        vm.prank(users.sender);
        usd.approve(address(sablierV2Pro), type(uint256).max);

        // Approve the SablierV2Pro contract to spend non-standard tokens from the `sender` account.
        vm.prank(users.sender);
        nonStandardToken.approve(address(sablierV2Pro), type(uint256).max);

        // Approve the SablierV2Pro contract to spend $USD from the `recipient` account.
        vm.prank(users.recipient);
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
        assertEq(a.cancelable, b.cancelable);
        assertEq(a.depositAmount, b.depositAmount);
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

    /// @dev Helper function to compare two SD59x18 arrays.
    function assertEq(SD59x18[] memory a, SD59x18[] memory b) internal {
        uint256 aLength = a.length;
        int256[] memory aInt256 = new int256[](aLength);
        for (uint256 i = 0; i < aLength; ) {
            aInt256[i] = SD59x18.unwrap(a[i]);
            unchecked {
                i += 1;
            }
        }

        uint256 bLength = b.length;
        int256[] memory bInt256 = new int256[](bLength);
        for (uint256 i = 0; i < bLength; ) {
            bInt256[i] = SD59x18.unwrap(b[i]);
            unchecked {
                i += 1;
            }
        }

        assertEq(aInt256, bInt256);
    }

    /// @dev Helper function to create a pro stream.
    function createDefaultStream() internal returns (uint256 streamId) {
        streamId = sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }
}
