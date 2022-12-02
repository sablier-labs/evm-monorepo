// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract GetWithdrawableAmount__Test is SablierV2LinearTest {
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
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(nonStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawableAmount__CliffTimeGreaterThanBlockTimestamp() external StreamExistent {
        vm.warp(daiStream.cliffTime - 1 seconds);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev When the cliff time is equal to the block timestamp, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CliffTimeEqualToBlockTimestamp() external {
        vm.warp(daiStream.cliffTime);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = WITHDRAW_AMOUNT_DAI - 100e18;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier CliffTimeLessThanBlockTimestamp() {
        _;
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        vm.warp(daiStream.stopTime + 1 seconds);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        vm.warp(daiStream.stopTime + 1 seconds);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        vm.warp(daiStream.stopTime);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        vm.warp(daiStream.stopTime);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = daiStream.depositAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__WithWithdrawals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals__6Decimals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        vm.warp(usdcStream.startTime + TIME_OFFSET);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(usdcStreamId);
        uint128 expectedWithdrawableAmount = WITHDRAW_AMOUNT_USDC;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__CurrentTimeLessThanStopTime__NoWithdrawals__18Decimals()
        external
        StreamExistent
        CliffTimeLessThanBlockTimestamp
    {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        uint128 actualWithdrawableAmount = sablierV2Linear.getWithdrawableAmount(daiStreamId);
        uint128 expectedWithdrawableAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
