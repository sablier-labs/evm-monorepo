// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "./../Integration.t.sol";

contract CancelOrder_Integration_Fuzz_Test is Integration_Test {
    /// @dev It should revert when the caller is not the seller.
    function testFuzz_RevertWhen_CallerNotSeller(address caller) external givenNotNull givenOPENStatus {
        vm.assume(caller != users.seller);

        // Set the fuzzed address as the caller.
        setMsgSender(caller);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierEscrow_CallerNotAuthorized.selector, defaultOrderId, caller, users.seller
            )
        );
        escrow.cancelOrder(defaultOrderId);
    }

    /// @dev Given enough fuzz runs, it should test cancelling an order at all possible times.
    function testFuzz_CancelOrder(uint64 warpTime) external givenNotNull givenOPENStatus whenCallerSeller {
        // Bound timestamp between now and 30 days after expiry.
        warpTime = boundUint64(warpTime, FEB_1_2026, ORDER_EXPIRY_TIME + 30 days);

        vm.warp(warpTime);

        // It should perform the ERC-20 transfer.
        expectCallToTransfer({ token: sellToken, to: users.seller, value: SELL_AMOUNT });

        // It should emit a {CancelOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({ orderId: defaultOrderId, seller: users.seller, sellAmount: SELL_AMOUNT });

        // Cancel the order.
        escrow.cancelOrder(defaultOrderId);

        // It should mark the order as cancelled.
        assertEq(escrow.statusOf(defaultOrderId), Escrow.Status.CANCELLED, "order.status");
        assertTrue(escrow.wasCanceled(defaultOrderId), "order.wasCanceled");
        assertFalse(escrow.wasFilled(defaultOrderId), "order.wasFilled");
    }
}
