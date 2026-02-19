// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "./../Integration.t.sol";

contract CreateOrder_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_CreateOrder(uint128 sellAmount, uint128 minBuyAmount, uint40 expiryTime) external {
        sellAmount = boundUint128(sellAmount, 1, MAX_UINT128);
        minBuyAmount = boundUint128(minBuyAmount, 1, MAX_UINT128);

        // If non-zero, bound to [now+1, now+5years]; otherwise keep 0 (never expires).
        if (expiryTime != 0) {
            expiryTime = boundUint40(expiryTime, getBlockTimestamp() + 1, getBlockTimestamp() + 5 * 365 days);
        }

        // Deal sell tokens to seller so any uint128 amount works.
        deal({ token: address(sellToken), to: users.seller, give: sellAmount });

        // Set seller as caller.
        setMsgSender(users.seller);

        uint256 expectedOrderId = escrow.nextOrderId();

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: sellToken, from: users.seller, to: address(escrow), value: sellAmount });

        // It should emit a {CreateOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId,
            seller: users.seller,
            buyer: users.buyer,
            sellToken: sellToken,
            buyToken: buyToken,
            sellAmount: sellAmount,
            minBuyAmount: minBuyAmount,
            expiryTime: expiryTime
        });

        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: sellAmount,
            buyToken: buyToken,
            minBuyAmount: minBuyAmount,
            buyer: users.buyer,
            expiryTime: expiryTime
        });

        // It should create the order with correct state.
        assertEq(orderId, expectedOrderId, "orderId");
        assertEq(escrow.getSeller(orderId), users.seller, "order.seller");
        assertEq(escrow.getBuyer(orderId), users.buyer, "order.buyer");
        assertEq(escrow.getSellToken(orderId), sellToken, "order.sellToken");
        assertEq(escrow.getBuyToken(orderId), buyToken, "order.buyToken");
        assertEq(escrow.getSellAmount(orderId), sellAmount, "order.sellAmount");
        assertEq(escrow.getMinBuyAmount(orderId), minBuyAmount, "order.minBuyAmount");
        assertEq(escrow.getExpiryTime(orderId), expiryTime, "order.expiryTime");
        assertFalse(escrow.wasCanceled(orderId), "order.wasCanceled");
        assertFalse(escrow.wasFilled(orderId), "order.wasFilled");
        assertEq(escrow.statusOf(orderId), Escrow.Status.OPEN, "order.status");
        assertEq(escrow.nextOrderId(), orderId + 1, "nextOrderId");
    }
}
