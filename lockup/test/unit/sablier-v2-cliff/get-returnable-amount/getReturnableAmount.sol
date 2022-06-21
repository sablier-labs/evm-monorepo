// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__UnitTest__GetReturnableAmount is SablierV2CliffUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need it.
        streamId = createDefaultDaiStream();
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetReturnableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualReturnableAmount = sablierV2Cliff.getReturnableAmount(nonStreamId);
        uint256 expectedReturnableAmount = 0;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev When the withdrawable amount is zero and there have been no withdrawals, it should return the
    /// deposit amount.
    function testGetReturnableAmount__WithdrawableAmountZero__NoWithdrawals() external {
        uint256 actualReturnableAmount = sablierV2Cliff.getReturnableAmount(streamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev When the withdrawable amount is zero and there have been withdrawals, it should return the
    /// correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountZero__WithWithdrawals() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualReturnableAmount = sablierV2Cliff.getReturnableAmount(streamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev When the withdrawable amount is not zero and there have been no withdrawals, it should return the
    /// correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__NoWithdrawals() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        uint256 actualReturnableAmount = sablierV2Cliff.getReturnableAmount(streamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI;
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }

    /// @dev When the withdrawable amount is not zero and there have been withdrawals, it should return the
    /// correct returnable amount.
    function testGetReturnableAmount__WithdrawableAmountNotZero__WithWithdrawals() external {
        vm.warp(daiStream.startTime + TIME_OFFSET + 1 seconds);
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualReturnableAmount = sablierV2Cliff.getReturnableAmount(streamId);
        uint256 expectedReturnableAmount = daiStream.depositAmount - WITHDRAW_AMOUNT_DAI - bn(1, 18);
        assertEq(actualReturnableAmount, expectedReturnableAmount);
    }
}
