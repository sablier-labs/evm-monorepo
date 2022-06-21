// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__GetWithdrawnAmount is SablierV2LinearUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        streamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawnAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Linear.getWithdrawnAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev When there haven't been withdrawals, it should return zero.
    function testGetWithdrawnAmount__NoWithdrawals() external {
        uint256 actualDepositAmount = sablierV2Linear.getWithdrawnAmount(streamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev When there have been withdrawals, it should return the correct withdrawn amount.
    function testGetWithdrawnAmount__WithWithdrawals() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(streamId, WITHDRAW_AMOUNT);
        uint256 actualDepositAmount = sablierV2Linear.getWithdrawnAmount(streamId);
        uint256 expectedDepositAmount = WITHDRAW_AMOUNT;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
