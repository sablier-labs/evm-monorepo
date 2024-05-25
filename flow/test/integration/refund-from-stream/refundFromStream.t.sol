// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract RefundFromStream_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierFlow.refundFromStream, (defaultStreamId, REFUND_AMOUNT));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        flow.refundFromStream({ streamId: nullStreamId, amount: REFUND_AMOUNT });
    }

    function test_RevertWhen_CallerRecipient() external whenNotDelegateCalled givenNotNull whenCallerIsNotTheSender {
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        flow.refundFromStream({ streamId: defaultStreamId, amount: REFUND_AMOUNT });
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsNotTheSender
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.eve));
        flow.refundFromStream({ streamId: defaultStreamId, amount: REFUND_AMOUNT });
    }

    function test_RevertWhen_RefundAmountZero() external whenNotDelegateCalled givenNotNull whenCallerIsTheSender {
        vm.expectRevert(Errors.SablierFlow_RefundAmountZero.selector);
        flow.refundFromStream({ streamId: defaultStreamId, amount: 0 });
    }

    function test_RevertWhen_Overrefund()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsTheSender
        whenRefundAmountNotZero
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFlow_Overrefund.selector,
                defaultStreamId,
                DEPOSIT_AMOUNT,
                DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT
            )
        );
        flow.refundFromStream({ streamId: defaultStreamId, amount: DEPOSIT_AMOUNT });
    }

    function test_RefundFromStream_PausedStream() external whenNotDelegateCalled givenNotNull whenCallerIsTheSender {
        flow.pause(defaultStreamId);

        expectCallToTransfer({ asset: dai, to: users.sender, amount: REFUND_AMOUNT });
        flow.refundFromStream({ streamId: defaultStreamId, amount: REFUND_AMOUNT });

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - REFUND_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_RefundFromStream_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsTheSender
        whenRefundAmountNotZero
        whenNoOverrefund
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        flow.deposit(streamId, DEPOSIT_AMOUNT);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        test_RefundFromStream(streamId, IERC20(address(usdt)));
    }

    function test_RefundFromStream()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsTheSender
        whenRefundAmountNotZero
        whenNoOverrefund
    {
        test_RefundFromStream(defaultStreamId, dai);
    }

    function test_RefundFromStream(uint256 streamId, IERC20 asset) internal {
        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({
            from: address(flow),
            to: users.sender,
            value: normalizeAmountWithStreamId(streamId, REFUND_AMOUNT)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: streamId, sender: users.sender, asset: asset, refundAmount: REFUND_AMOUNT });

        expectCallToTransfer({
            asset: asset,
            to: users.sender,
            amount: normalizeAmountWithStreamId(streamId, REFUND_AMOUNT)
        });
        flow.refundFromStream({ streamId: streamId, amount: REFUND_AMOUNT });

        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - REFUND_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
