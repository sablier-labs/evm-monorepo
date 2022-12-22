// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ProTest } from "../ProTest.t.sol";

contract GetWithdrawnAmount__Test is ProTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualDepositAmount = pro.getWithdrawnAmount(nonStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should return zero.
    function testGetWithdrawnAmount__NoWithdrawals() external StreamExistent {
        uint128 actualDepositAmount = pro.getWithdrawnAmount(daiStreamId);
        uint128 expectedDepositAmount = 0;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }

    /// @dev it should return the correct withdrawn amount.
    function testGetWithdrawnAmount__WithWithdrawals() external StreamExistent {
        vm.warp({ timestamp: daiStream.stopTime });
        uint128 withdrawAmount = 100e18;
        pro.withdraw(daiStreamId, users.recipient, withdrawAmount);
        uint128 actualDepositAmount = pro.getWithdrawnAmount(daiStreamId);
        uint128 expectedDepositAmount = withdrawAmount;
        assertEq(actualDepositAmount, expectedDepositAmount);
    }
}
