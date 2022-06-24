// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__GetWithdrawnAmount is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }
}

contract SablierV2Linear__GetWithdrawnAmount__StreamNonExistent is SablierV2Linear__GetWithdrawnAmount {
    /// @dev it should return zero.
    function testGetWithdrawnAmount() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Linear.getWithdrawnAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}

contract StreamExistent {}

contract SablierV2Linear__GetWithdrawnAmount__NoWithdrawals is SablierV2Linear__GetWithdrawnAmount, StreamExistent {
    /// @dev it should return zero.
    function testGetWithdrawnAmount() external {
        uint256 actualDepositAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}

contract SablierV2Linear__GetWithdrawnAmount__WithWithdrawals is SablierV2Linear__GetWithdrawnAmount, StreamExistent {
    /// @dev it should return the correct withdrawn amount.
    function testGetWithdrawnAmount() external {
        vm.warp(daiStream.startTime + TIME_OFFSET);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        uint256 actualDepositAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint256 expectedDepositAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
