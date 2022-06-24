// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__WithdrawTo is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;
    address internal toAlice;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);

        // Make Alice the address that will receive the tokens.
        toAlice = users.alice;
    }
}

contract SablierV2Linear__WithdrawTo__StreamNonExistent is SablierV2Linear__WithdrawTo {
    /// @dev it should revert.
    function testCannotWithdrawTo() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(nonStreamId, toAlice, withdrawAmount);
    }
}

contract StreamExistent {}

contract SablierV2Linear__WithdrawTo__ToZeroAddress is SablierV2Linear__WithdrawTo, StreamExistent {
    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ToZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawZeroAddress.selector));
        address toZero = address(0);
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toZero, withdrawAmount);
    }
}

contract ToNonZeroAddress {}

contract SablierV2Linear__WithdrawTo__CallerSender is SablierV2Linear__WithdrawTo, StreamExistent, ToNonZeroAddress {
    /// @dev it should revert.
    function testCannotWithdrawTo() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.sender));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }
}

contract SablierV2Linear__WithdrawTo__CallerThirdParty is
    SablierV2Linear__WithdrawTo,
    StreamExistent,
    ToNonZeroAddress
{
    /// @dev it should revert.
    function testCannotWithdrawTo() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }
}

contract CallerRecipient {}

contract SablierV2Linear__WithdrawTo__WithdrawAmountZero is
    SablierV2Linear__WithdrawTo,
    StreamExistent,
    ToNonZeroAddress,
    CallerRecipient
{
    /// @dev it should revert.
    function testCannotWithdrawTo() external {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }
}

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount() external {
        uint256 withdrawAmountMaxUint256 = UINT256_MAX;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountMaxUint256);
    }
}

contract WithdrawAmountLessThanOrEqualToWithdrawableAmount {}

contract SablierV2Linear__WithdrawTo__ToRecipient is
    SablierV2Linear__WithdrawTo,
    StreamExistent,
    ToNonZeroAddress,
    CallerRecipient,
    WithdrawAmountNotZero,
    WithdrawAmountLessThanOrEqualToWithdrawableAmount
{
    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
    }
}

contract ToThirdParty {}

contract SablierV2Linear__WithdrawTo__StreamEnded is
    SablierV2Linear__WithdrawTo,
    StreamExistent,
    ToNonZeroAddress,
    CallerRecipient,
    WithdrawAmountNotZero,
    WithdrawAmountLessThanOrEqualToWithdrawableAmount,
    ToThirdParty
{
    /// @dev it should make the withdrawal and delete the stream.
    function testWithdrawTo() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = daiStream.depositAmount;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__Event() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 withdrawAmount = daiStream.depositAmount;
        emit Withdraw(daiStreamId, toAlice, withdrawAmount);
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }
}

contract SablierV2Linear__WithdrawTo__StreamOngoing is
    SablierV2Linear__WithdrawTo,
    StreamExistent,
    ToNonZeroAddress,
    CallerRecipient,
    WithdrawAmountNotZero,
    WithdrawAmountLessThanOrEqualToWithdrawableAmount,
    ToThirdParty
{
    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdrawTo() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__Event() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT_DAI;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(daiStreamId, toAlice, withdrawAmount);
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }
}
