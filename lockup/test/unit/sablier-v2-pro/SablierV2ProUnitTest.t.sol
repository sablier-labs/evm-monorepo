/* solhint-disable var-name-mixedcase */
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";

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
        uint256[] segmentExponents,
        uint256[] segmentMilestones,
        bool cancelable
    );

    /// CONSTANTS ///

    uint256 internal immutable DEFAULT_SEGMENT_AMOUNT_1 = bn(2_500);
    uint256 internal immutable DEFAULT_SEGMENT_AMOUNT_2 = bn(7_500);
    uint256 internal constant DEFAULT_SEGMENT_EXPONENT_1 = 1;
    uint256 internal constant DEFAULT_SEGMENT_EXPONENT_2 = 2;
    uint256 internal constant DEFAULT_SEGMENT_MILESTONE_1 = 5_100 seconds;
    uint256 internal constant DEFAULT_SEGMENT_MILESTONE_2 = 10_100 seconds;
    uint256 internal constant DEFAULT_TIME_OFFSET = 5_000 seconds;
    uint256 internal immutable DEFAULT_WITHDRAW_AMOUNT = bn(2500);

    /// OTHER TESTING VARIABLES ///

    SablierV2Pro internal sablierV2Pro = new SablierV2Pro();
    ISablierV2Pro.Stream internal stream;

    // SETUP FUNCTION ///

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        uint256[] memory DEFAULT_SEGMENT_AMOUNTS = fixedSizeToDynamic(
            [DEFAULT_SEGMENT_AMOUNT_1, DEFAULT_SEGMENT_AMOUNT_2]
        );
        uint256[] memory DEFAULT_SEGMENT_EXPONENTS = fixedSizeToDynamic(
            [DEFAULT_SEGMENT_EXPONENT_1, DEFAULT_SEGMENT_EXPONENT_2]
        );
        uint256[] memory DEFAULT_SEGMENT_MILESTONES = fixedSizeToDynamic(
            [DEFAULT_SEGMENT_MILESTONE_1, DEFAULT_SEGMENT_MILESTONE_2]
        );

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
        require(a.length == b.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < a.length; i++) {
            assertEq(a[i], b[i]);
        }
    }

    /// @dev Helper function to return a dynamic array from a single number.
    function fixedSizeToDynamic(uint256 toReturn) internal pure returns (uint256[] memory result) {
        uint256[] memory aux = new uint256[](1);
        aux[0] = toReturn;

        result = aux;
    }

    /// @dev Helper function to return a dynamic array from a fixed size array.
    function fixedSizeToDynamic(uint256[2] memory toReturn) internal pure returns (uint256[] memory result) {
        uint256[] memory aux = new uint256[](2);
        aux[0] = toReturn[0];
        aux[1] = toReturn[1];

        result = aux;
    }

    /// @dev Helper function to return a dynamic array from a fixed size array.
    function fixedSizeToDynamic(uint256[6] memory toReturn) internal pure returns (uint256[] memory result) {
        uint256[] memory aux = new uint256[](6);
        aux[0] = toReturn[0];
        aux[1] = toReturn[1];
        aux[2] = toReturn[2];
        aux[3] = toReturn[3];
        aux[4] = toReturn[4];
        aux[5] = toReturn[5];

        result = aux;
    }
}
