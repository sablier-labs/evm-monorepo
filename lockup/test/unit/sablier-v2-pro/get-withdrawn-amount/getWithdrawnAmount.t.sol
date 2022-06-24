// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__GetWithdrawnAmount is SablierV2ProUnitTest {
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

contract SablierV2Pro__GetWithdrawnAmount__StreamNonExistent is SablierV2Pro__GetWithdrawnAmount {
    /// @dev it should return zero.
    function testGetWithdrawnAmount() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}

contract StreamExistent {}

contract SablierV2Pro__GetWithdrawnAmount__NoWithdrawals is SablierV2Pro__GetWithdrawnAmount, StreamExistent {
    /// @dev it should return zero.
    function testGetWithdrawnAmount() external {
        uint256 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(daiStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}

contract SablierV2Pro__GetWithdrawnAmount__WithWithdrawals is SablierV2Pro__GetWithdrawnAmount, StreamExistent {
    /// @dev it should return the correct withdrawn amount.
    function testGetWithdrawnAmount() external {
        vm.warp(daiStream.stopTime);
        uint256 withdrawAmount = bn(100, 18);
        sablierV2Pro.withdraw(daiStreamId, withdrawAmount);
        uint256 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(daiStreamId);
        uint256 expectedDepositAmount = withdrawAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
