// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract CancelOrder_Integration_Concrete_Test is Integration_Test {
    function test_RevertGiven_Null() external {
        // It should revert.
        expectRevert_Null(abi.encodeCall(escrow.cancelOrder, (nullOrderId)));
    }

    function test_RevertWhen_CallerNotSeller() external givenNotNull {
        // Change caller to Buyer.
        setMsgSender(users.buyer);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierEscrow_CallerNotAuthorized.selector, defaultOrderId, users.buyer, users.seller
            )
        );
        escrow.cancelOrder(defaultOrderId);
    }

    function test_RevertGiven_Filled() external givenNotNull whenCallerSeller {
        // Fill the default order.
        setMsgSender(users.buyer);
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);

        setMsgSender(users.seller);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_OrderFilled.selector, defaultOrderId));
        escrow.cancelOrder(defaultOrderId);
    }

    function test_RevertGiven_Canceled() external givenNotNull whenCallerSeller {
        // Cancel the default order.
        escrow.cancelOrder(defaultOrderId);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_OrderCancelled.selector, defaultOrderId));
        escrow.cancelOrder(defaultOrderId);
    }

    function test_GivenExpired() external givenNotNull whenCallerSeller {
        // Warp past expiry.
        vm.warp(ORDER_EXPIRY_TIME + 1);

        // It should perform the ERC-20 transfers.
        expectCallToTransfer({ token: sellToken, to: users.seller, value: SELL_AMOUNT });

        // It should emit a {CancelOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({ orderId: defaultOrderId, seller: users.seller, sellAmount: SELL_AMOUNT });

        // Cancel the order.
        escrow.cancelOrder(defaultOrderId);

        // It should cancel the order.
        assertEq(escrow.statusOf(defaultOrderId), Escrow.Status.CANCELLED, "order.status should be CANCELLED");
        assertTrue(escrow.wasCanceled(defaultOrderId), "order.wasCanceled");
    }

    function test_GivenOpen() external givenNotNull whenCallerSeller {
        // It should perform the ERC-20 transfers.
        expectCallToTransfer({ token: sellToken, to: users.seller, value: SELL_AMOUNT });

        // It should emit a {CancelOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({ orderId: defaultOrderId, seller: users.seller, sellAmount: SELL_AMOUNT });

        // Cancel the order.
        escrow.cancelOrder(defaultOrderId);

        // It should cancel the order.
        assertEq(escrow.statusOf(defaultOrderId), Escrow.Status.CANCELLED, "order.status");
        assertTrue(escrow.wasCanceled(defaultOrderId), "order.wasCanceled");
    }
}
