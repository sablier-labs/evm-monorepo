// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__GetWithdrawableAmount is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default dai stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(nonStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the cliff time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external {
        vm.warp(daiStream.cliffTime - 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the cliff time is equal to the block timestamp, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CliffTimeEqualToBlockTimestamp() external {
        vm.warp(daiStream.cliffTime);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT_DAI - bn(100, 18);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external {
        vm.warp(daiStream.stopTime + 1 seconds);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external {
        vm.warp(daiStream.stopTime);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external {
        vm.warp(daiStream.stopTime);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time and there have been withdrawals, it should
    /// return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time, there have been no withdrawals and the token
    /// has 6 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals__6Decimals() external {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + TIME_OFFSET);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(usdcStreamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT_USDC;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the current time is less than the stop time, there have been no withdrawals and the token
    /// has 18 decimals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals__18Decimals() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
