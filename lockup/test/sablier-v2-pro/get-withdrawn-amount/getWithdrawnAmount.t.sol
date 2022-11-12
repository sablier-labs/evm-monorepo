// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2ProBaseTest } from "../SablierV2ProBaseTest.t.sol";

contract GetWithdrawnAmount__Tests is SablierV2ProBaseTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(nonStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__NoWithdrawals() external StreamExistent {
        uint256 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(daiStreamId);
        uint256 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev it should return the correct withdrawn amount.
    function testGetWithdrawnAmount__WithWithdrawals() external StreamExistent {
        vm.warp(daiStream.stopTime);
        uint256 withdrawAmount = 100e18;
        sablierV2Pro.withdraw(daiStreamId, withdrawAmount);
        uint256 actualDepositAmount = sablierV2Pro.getWithdrawnAmount(daiStreamId);
        uint256 expectedDepositAmount = withdrawAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
