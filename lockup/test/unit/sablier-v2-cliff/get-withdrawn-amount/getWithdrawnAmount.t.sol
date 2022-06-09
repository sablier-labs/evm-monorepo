// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__GetWithdrawnAmount__UnitTest is SablierV2CliffUnitTest {
    uint256 streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawnAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Cliff.getWithdrawnAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev When there haven't been withdrawals, it should return zero.
    function testGetWithdrawnAmount__NoWithdrawals() external {
        uint256 actualDepositAmount = sablierV2Cliff.getWithdrawnAmount(streamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev When there have been withdrawals, it should return the correct withdrawn amount.
    function testGetWithdrawnAmount__WithWithdrawals() external {
        vm.warp(stream.startTime + TIME_OFFSET);
        sablierV2Cliff.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 actualDepositAmount = sablierV2Cliff.getWithdrawnAmount(streamId);
        uint256 expectedDepositAmount = WITHDRAW_AMOUNT;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
