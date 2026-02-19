// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "./../Integration.t.sol";

contract CancelOrder_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_RevertGiven_FilledOrCancelled(bool toFillOrCancel) external {
        if (toFillOrCancel) {
            // Fill the default order.
            setMsgSender(users.buyer);
            escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);

            // It should revert.
            setMsgSender(users.seller);
            vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_OrderFilled.selector, defaultOrderId));
        } else {
            // Cancel the default order.
            escrow.cancelOrder(defaultOrderId);

            // It should revert.
            vm.expectRevert(abi.encodeWithSelector(Errors.SablierEscrow_OrderCancelled.selector, defaultOrderId));
        }

        escrow.cancelOrder(defaultOrderId);
    }

    function testFuzz_CancelOrder(
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint40 expiryTime,
        uint40 timeJump
    )
        external
    {
        sellAmount = boundUint128(sellAmount, 1, MAX_UINT128);
        minBuyAmount = boundUint128(minBuyAmount, 1, MAX_UINT128);
        expiryTime = boundUint40(expiryTime, getBlockTimestamp() + 1, getBlockTimestamp() + 5 * 365 days);
        timeJump = boundUint40(timeJump, 0, uint40(10 * 365 days));

        // Deal sell tokens to seller.
        deal({ token: address(sellToken), to: users.seller, give: sellAmount });

        // Create the order as seller.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: sellAmount,
            buyToken: buyToken,
            minBuyAmount: minBuyAmount,
            buyer: users.buyer,
            expiryTime: expiryTime
        });

        // Warp forward — may land before or after expiry.
        vm.warp(getBlockTimestamp() + timeJump);

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: sellToken, to: users.seller, value: sellAmount });

        // It should emit a {CancelOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({ orderId: orderId, seller: users.seller, sellAmount: sellAmount });

        // Cancel the order.
        escrow.cancelOrder(orderId);

        // It should mark the order as cancelled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.CANCELLED, "order.status");
        assertTrue(escrow.wasCanceled(orderId), "order.wasCanceled");
        assertFalse(escrow.wasFilled(orderId), "order.wasFilled");
    }
}
