// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetReturnableAmount is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default dai stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();
    }
}

contract SablierV2Linear__GetReturnableAmount__StreamNonExistent is SablierV2Linear__GetReturnableAmount {
    /// @dev it should return zero.
    function testGetReturnableAmount() external {
        uint256 nonStreamId = 1729;
        uint256 actualReturnableAmount = sablierV2Linear.getReturnableAmount(nonStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}

contract StreamExistent {}

contract SablierV2Linear__GetReturnableAmount__WithdrawableAmountZero__NoWithdrawals is
    SablierV2Linear__GetReturnableAmount,
    StreamExistent
{
    /// @dev it should return the deposit amount.
    function testGetReturnableAmount__WithdrawableAmountZero__NoWithdrawals() external {
        uint256 actualReturnableAmount = sablierV2Linear.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}

contract SablierV2Linear__GetReturnableAmount__WithdrawableAmountZero__WithWithdrawals is
    SablierV2Linear__GetReturnableAmount,
    StreamExistent
{
    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualReturnableAmount = sablierV2Linear.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}

contract SablierV2Linear__GetReturnableAmount__WithdrawableAmountNotZero__NoWithdrawals is
    SablierV2Linear__GetReturnableAmount
{
    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        uint256 actualReturnableAmount = sablierV2Linear.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}

contract SablierV2Linear__GetReturnableAmount__WithdrawableAmountNotZero__WithWithdrawals is
    SablierV2Linear__GetReturnableAmount
{
    /// @dev it should return the correct returnable amount.
    function testGetReturnableAmount() external {
        vm.warp(daiStream.startTime + TIME_OFFSET + 1 seconds);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualReturnableAmount = sablierV2Linear.getReturnableAmount(daiStreamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI - bn(1, 18);
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
