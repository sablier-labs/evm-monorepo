// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetWithdrawableAmount is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default dai stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }
}

contract SablierV2Linear__GetWithdrawableAmount__StreamNonExistent is SablierV2Linear__GetWithdrawableAmount {
    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount() external {
        uint256 nonStreamId = 1729;
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(nonStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract StreamExistent {}

contract SablierV2Linear__GetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent
{
    /// @dev it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external {
        vm.warp(daiStream.cliffTime - 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CliffTimeEqualToBlockTimestamp is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent
{
    /// @dev When the cliff time is equal to the block timestamp, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CliffTimeEqualToBlockTimestamp() external {
        vm.warp(daiStream.cliffTime);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT_DAI - bn(100, 18);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract CliffTimeLessThanBlockTimestamp {}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount() external {
        vm.warp(daiStream.stopTime + 1 seconds);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount() external {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount() external {
        vm.warp(daiStream.stopTime);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount() external {
        vm.warp(daiStream.stopTime);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals__Token6Decimals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount() external {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + TIME_OFFSET);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(usdcStreamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT_USDC;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}

contract SablierV2Linear__GetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals__Token18Decimals is
    SablierV2Linear__GetWithdrawableAmount,
    StreamExistent,
    CliffTimeLessThanBlockTimestamp
{
    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        uint256 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint256 expectedWithdrawableAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
