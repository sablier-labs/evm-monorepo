// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Concrete_Test } from "../Concrete.t.sol";

contract RefundMax_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function setUp() public override {
        Shared_Integration_Concrete_Test.setUp();

        // Deposit to the default stream.
        depositToDefaultStream();
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.refundMax, (defaultStreamId));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData = abi.encodeCall(flow.refundMax, (nullStreamId));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_CallerRecipient() external whenNoDelegateCall givenNotNull whenCallerNotSender {
        bytes memory callData = abi.encodeCall(flow.refundMax, (defaultStreamId));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty() external whenNoDelegateCall givenNotNull whenCallerNotSender {
        bytes memory callData = abi.encodeCall(flow.refundMax, (defaultStreamId));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_GivenPaused() external whenNoDelegateCall givenNotNull whenCallerSender {
        flow.pause(defaultStreamId);

        // It should make the refund.
        _test_RefundMax({ streamId: defaultStreamId, token: usdc, depositedAmount: DEPOSIT_AMOUNT_6D });
    }

    function test_GivenNotPaused() external whenNoDelegateCall givenNotNull whenCallerSender {
        // It should make the refund.
        _test_RefundMax({ streamId: defaultStreamId, token: usdc, depositedAmount: DEPOSIT_AMOUNT_6D });
    }

    function _test_RefundMax(uint256 streamId, IERC20 token, uint128 depositedAmount) private {
        uint256 previousAggregateAmount = flow.aggregateBalance(token);
        uint128 refundableAmount = flow.refundableAmountOf(streamId);

        // It should emit 1 {Transfer}, 1 {RefundFromFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: refundableAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RefundFromFlowStream({ streamId: streamId, sender: users.sender, amount: refundableAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: token, to: users.sender, amount: refundableAmount });
        flow.refundMax(streamId);

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = depositedAmount - refundableAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should decrease the aggregate amount.
        assertEq(flow.aggregateBalance(token), previousAggregateAmount - refundableAmount, "aggregate amount");
    }
}
