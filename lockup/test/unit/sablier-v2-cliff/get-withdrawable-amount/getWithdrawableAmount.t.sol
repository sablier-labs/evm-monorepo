// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__GetWithdrawableAmount__UnitTest is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need one.
        streamId = createDefaultCliffStream();
    }

    /// @dev When the cliff stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 withdrawableAmount = sablierV2Cliff.getWithdrawableAmount(nonStreamId);
        assertEq(0, withdrawableAmount);
    }

    /// @dev When the cliff time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external {
        vm.warp(cliffStream.cliffTime - 1 seconds);
        uint256 withdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(0, withdrawableAmount);
    }

    /// @dev When the cliff time is equal to the block timestamp
    function testGetWithdrawableAmount__CliffTimeEqualToBlockTimestamp() external {
        vm.warp(cliffStream.cliffTime);
        uint256 expectedWithdrawableAmount = bn(900);
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external {
        vm.warp(cliffStream.stopTime + 1 seconds);
        uint256 expectedWithdrawableAmount = cliffStream.depositAmount;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external {
        vm.warp(cliffStream.stopTime + 1 seconds);
        sablierV2Cliff.withdraw(streamId, DEFAULT_WITHDRAW_AMOUNT);
        uint256 expectedWithdrawableAmount = cliffStream.depositAmount - DEFAULT_WITHDRAW_AMOUNT;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external {
        vm.warp(cliffStream.stopTime);
        uint256 expectedWithdrawableAmount = cliffStream.depositAmount;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external {
        vm.warp(cliffStream.stopTime);
        sablierV2Cliff.withdraw(streamId, DEFAULT_WITHDRAW_AMOUNT);
        uint256 expectedWithdrawableAmount = cliffStream.depositAmount - DEFAULT_WITHDRAW_AMOUNT;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been no withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals() external {
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);
        uint256 expectedWithdrawableAmount = DEFAULT_WITHDRAW_AMOUNT;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals() external {
        vm.warp(cliffStream.startTime + DEFAULT_TIME_OFFSET);
        sablierV2Cliff.withdraw(streamId, DEFAULT_WITHDRAW_AMOUNT);
        uint256 expectedWithdrawableAmount = 0;
        uint256 actualWithdrawableAmount = sablierV2Cliff.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }
}
