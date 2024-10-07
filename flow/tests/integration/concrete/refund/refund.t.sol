// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Refund_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Deposit to the default stream.
        depositToDefaultStream();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.refund, (defaultStreamId, REFUND_AMOUNT_6D));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.refund, (nullStreamId, REFUND_AMOUNT_6D));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_CallerRecipient() external whenNoDelegateCall givenNotNull whenCallerNotSender {
        bytes memory callData = abi.encodeCall(flow.refund, (defaultStreamId, REFUND_AMOUNT_6D));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty() external whenNoDelegateCall givenNotNull whenCallerNotSender {
        bytes memory callData = abi.encodeCall(flow.refund, (defaultStreamId, REFUND_AMOUNT_6D));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_RevertWhen_RefundAmountZero() external whenNoDelegateCall givenNotNull whenCallerSender {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_RefundAmountZero.selector, defaultStreamId));
        flow.refund({ streamId: defaultStreamId, amount: 0 });
    }

    function test_RevertWhen_OverRefund()
        external
        whenNoDelegateCall
        givenNotNull
        whenCallerSender
        whenRefundAmountNotZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_RefundOverflow.selector,
                defaultStreamId,
                DEPOSIT_AMOUNT_6D,
                DEPOSIT_AMOUNT_6D - ONE_MONTH_DEBT_6D
            )
        );
        flow.refund({ streamId: defaultStreamId, amount: DEPOSIT_AMOUNT_6D });
    }

    function test_GivenPaused()
        external
        whenNoDelegateCall
        givenNotNull
        whenCallerSender
        whenRefundAmountNotZero
        whenNoOverRefund
    {
        flow.pause(defaultStreamId);

        // It should make the refund.
        _test_Refund({
            streamId: defaultStreamId,
            token: usdc,
            depositedAmount: DEPOSIT_AMOUNT_6D,
            refundAmount: REFUND_AMOUNT_6D
        });
    }

    function test_WhenTokenMissesERC20Return()
        external
        whenNoDelegateCall
        givenNotNull
        whenCallerSender
        whenRefundAmountNotZero
        whenNoOverRefund
        givenNotPaused
    {
        uint256 streamId = createDefaultStream(IERC20(address(usdt)));
        depositDefaultAmount(streamId);

        // It should make the refund.
        _test_Refund({
            streamId: streamId,
            token: IERC20(address(usdt)),
            depositedAmount: DEPOSIT_AMOUNT_6D,
            refundAmount: REFUND_AMOUNT_6D
        });
    }

    function test_GivenTokenNotHave18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenCallerSender
        whenRefundAmountNotZero
        whenNoOverRefund
        givenNotPaused
        whenTokenNotMissERC20Return
    {
        // It should make the refund.
        _test_Refund({
            streamId: defaultStreamId,
            token: usdc,
            depositedAmount: DEPOSIT_AMOUNT_6D,
            refundAmount: REFUND_AMOUNT_6D
        });
    }

    function test_GivenTokenHas18Decimals()
        external
        whenNoDelegateCall
        givenNotNull
        whenCallerSender
        whenRefundAmountNotZero
        whenNoOverRefund
        givenNotPaused
        whenTokenNotMissERC20Return
    {
        uint256 streamId = createDefaultStream(IERC20(address(dai)));
        depositDefaultAmount(streamId);

        // It should make the refund.
        _test_Refund({
            streamId: streamId,
            token: dai,
            depositedAmount: DEPOSIT_AMOUNT_18D,
            refundAmount: REFUND_AMOUNT_18D
        });
    }

    function _test_Refund(uint256 streamId, IERC20 token, uint128 depositedAmount, uint128 refundAmount) private {
        uint256 previousAggregateAmount = flow.aggregateBalance(token);

        // It should emit 1 {Transfer}, 1 {RefundFromFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({ streamId: streamId, sender: users.sender, amount: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: token, to: users.sender, amount: refundAmount });
        flow.refund({ streamId: streamId, amount: refundAmount });

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = depositedAmount - refundAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // Assert that the refund amounts equal.
        assertEq(refundAmount, refundAmount);

        // It should decrease the aggregate amount.
        assertEq(flow.aggregateBalance(token), previousAggregateAmount - refundAmount, "aggregate amount");
    }
}
