// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Helpers } from "src/libraries/Helpers.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract Refund_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        depositToDefaultStream();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(flow.refund, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        bytes memory callData = abi.encodeCall(flow.refund, (nullStreamId, REFUND_AMOUNT));
        expectRevert_Null(callData);
    }

    function test_RevertWhen_CallerRecipient() external whenNotDelegateCalled givenNotNull whenCallerIsNotSender {
        bytes memory callData = abi.encodeCall(flow.refund, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsNotSender
    {
        bytes memory callData = abi.encodeCall(flow.refund, (defaultStreamId, REFUND_AMOUNT));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_RevertWhen_RefundAmountZero() external whenNotDelegateCalled givenNotNull whenCallerIsSender {
        vm.expectRevert(Errors.SablierFlow_RefundAmountZero.selector);
        flow.refund({ streamId: defaultStreamId, amount: 0 });
    }

    function test_RevertWhen_Overrefund()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsSender
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
        flow.refund({ streamId: defaultStreamId, amount: DEPOSIT_AMOUNT });
    }

    function test_Refund_PausedStream() external whenNotDelegateCalled givenNotNull whenCallerIsSender {
        flow.pause(defaultStreamId);

        expectCallToTransfer({ asset: dai, to: users.sender, amount: REFUND_AMOUNT });
        flow.refund({ streamId: defaultStreamId, amount: REFUND_AMOUNT });

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - REFUND_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    function test_Refund_AssetNot18Decimals()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsSender
        whenRefundAmountNotZero
        whenNoOverrefund
    {
        // Set the timestamp to 1 month ago to create the stream with the same `lastTimeUpdate` as `defaultStreamId`.
        vm.warp({ newTimestamp: WARP_ONE_MONTH - ONE_MONTH });
        uint256 streamId = createDefaultStreamWithAsset(IERC20(address(usdt)));
        flow.deposit(streamId, TRANSFER_AMOUNT_6D);
        vm.warp({ newTimestamp: WARP_ONE_MONTH });

        test_Refund(streamId, IERC20(address(usdt)), 6);
    }

    function test_Refund()
        external
        whenNotDelegateCalled
        givenNotNull
        whenCallerIsSender
        whenRefundAmountNotZero
        whenNoOverrefund
    {
        test_Refund(defaultStreamId, dai, 18);
    }

    function test_Refund(uint256 streamId, IERC20 asset, uint8 assetDecimals) internal {
        uint128 transferAmount = Helpers.calculateTransferAmount(REFUND_AMOUNT, assetDecimals);

        vm.expectEmit({ emitter: address(asset) });
        emit IERC20.Transfer({ from: address(flow), to: users.sender, value: transferAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: streamId, sender: users.sender, asset: asset, refundAmount: REFUND_AMOUNT });

        expectCallToTransfer({ asset: asset, to: users.sender, amount: transferAmount });
        flow.refund({ streamId: streamId, amount: REFUND_AMOUNT });

        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - REFUND_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
