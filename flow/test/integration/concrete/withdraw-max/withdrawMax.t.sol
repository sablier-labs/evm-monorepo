// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract WithdrawMax_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit to the default stream.
        depositToDefaultStream();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.withdrawMax, (defaultStreamId, users.recipient));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.withdrawMax, (nullStreamId, users.recipient));
        expectRevert_Null(callData);
    }

    function test_GivenPaused() external whenNoDelegateCall givenNotNull {
        // Pause the stream.
        flow.pause(defaultStreamId);

        // Withdraw the maximum amount.
        _test_WithdrawMax();
    }

    function test_GivenNotPaused() external whenNoDelegateCall givenNotNull {
        // Withdraw the maximum amount.
        _test_WithdrawMax();
    }

    function _test_WithdrawMax() private {
        uint128 withdrawAmount = ONE_MONTH_DEBT_6D;

        // It should emit 1 {Transfer}, 1 {WithdrawFromFlowStream} and 1 {MetadataUpdated} events.
        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: address(flow), to: users.recipient, value: withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: defaultStreamId,
            to: users.recipient,
            token: IERC20(address(usdc)),
            caller: users.sender,
            protocolFeeAmount: 0,
            withdrawAmount: withdrawAmount,
            snapshotTime: getBlockTimestamp()
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: usdc, to: users.recipient, amount: withdrawAmount });

        uint128 actualWithdrawAmount = flow.withdrawMax(defaultStreamId, users.recipient);

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT_6D - ONE_MONTH_DEBT_6D;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should set the snapshot debt to zero.
        uint128 actualSnapshotDebt = flow.getSnapshotDebt(defaultStreamId);
        assertEq(actualSnapshotDebt, 0, "snapshot debt");

        // It should update snapshot time.
        uint128 actualSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        assertEq(actualSnapshotTime, getBlockTimestamp(), "snapshot time");

        // Assert that the withdraw amounts match.
        assertEq(actualWithdrawAmount, withdrawAmount);
    }
}
