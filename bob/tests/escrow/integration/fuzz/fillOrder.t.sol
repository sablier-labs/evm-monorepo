// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../Integration.t.sol";

contract FillOrder_Integration_Fuzz_Test is Integration_Test {
    function testFuzz_RevertGiven_Expired(uint40 timeJump) external {
        // Bound timeJump so it lands at or past expiry.
        timeJump = boundUint40(timeJump, ORDER_EXPIRY_TIME, MAX_UINT40 - 1);

        // Warp past expiry.
        vm.warp(timeJump);

        // It should revert.
        setMsgSender(users.buyer);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrow_OrderNotOpen.selector, defaultOrderId, Escrow.Status.EXPIRED)
        );
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);
    }

    function testFuzz_FillOrder_GivenTradeFeeZero(uint128 buyAmount, uint40 timeJump) external {
        // Set the trade fee to zero before creating the order.
        setMsgSender(address(comptroller));
        escrow.setTradeFee(ZERO);

        _testFillOrder({
            orderId: defaultOrderId,
            buyAmount: buyAmount,
            timeJump: timeJump,
            buyer: users.buyer,
            fee: ZERO
        });
    }

    function testFuzz_FillOrder_GivenNoDesignatedBuyer(uint128 buyAmount, uint40 timeJump, address buyer) external {
        vm.assume(buyer != address(0) && buyer != users.seller);
        vm.assume(buyer != address(escrow) && buyer != address(comptroller));

        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: SELL_AMOUNT,
            buyToken: buyToken,
            minBuyAmount: MIN_BUY_AMOUNT,
            buyer: address(0),
            expiryTime: ORDER_EXPIRY_TIME
        });

        _testFillOrder({
            orderId: orderId,
            buyAmount: buyAmount,
            timeJump: timeJump,
            buyer: buyer,
            fee: DEFAULT_TRADE_FEE
        });
    }

    function testFuzz_FillOrder(uint128 buyAmount, uint40 timeJump) external {
        _testFillOrder({
            orderId: defaultOrderId,
            buyAmount: buyAmount,
            timeJump: timeJump,
            buyer: users.buyer,
            fee: DEFAULT_TRADE_FEE
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    PRIVATE HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testFillOrder(uint256 orderId, uint128 buyAmount, uint40 timeJump, address buyer, UD60x18 fee) private {
        // Bound amounts.
        buyAmount = boundUint128(buyAmount, MIN_BUY_AMOUNT, MAX_UINT128);

        // Bound timing: expiryTime in future, timeJump stays before expiry so order remains OPEN.
        uint40 maxJump = ORDER_EXPIRY_TIME - getBlockTimestamp() - 1;
        timeJump = boundUint40(timeJump, 0, maxJump);

        // Deal tokens.
        deal({ token: address(buyToken), to: buyer, give: buyAmount });

        // Warp forward (stays before expiry).
        vm.warp(getBlockTimestamp() + timeJump);

        // Compute fees.
        uint128 feeFromSellAmount = ud(SELL_AMOUNT).mul(fee).intoUint128();
        uint128 feeFromBuyAmount = ud(buyAmount).mul(fee).intoUint128();
        uint128 sellAmountAfterFee = SELL_AMOUNT - feeFromSellAmount;
        uint128 buyAmountAfterFee = buyAmount - feeFromBuyAmount;

        // Switch to buyer.
        setMsgSender(buyer);
        buyToken.approve(address(escrow), buyAmount);

        // Expect ERC-20 transfer calls.
        if (feeFromBuyAmount > 0) {
            expectCallToTransferFrom({
                token: buyToken,
                from: buyer,
                to: address(comptroller),
                value: feeFromBuyAmount
            });
        }
        if (feeFromSellAmount > 0) {
            expectCallToTransfer({ token: sellToken, to: address(comptroller), value: feeFromSellAmount });
        }
        expectCallToTransferFrom({ token: buyToken, from: buyer, to: users.seller, value: buyAmountAfterFee });
        expectCallToTransfer({ token: sellToken, to: buyer, value: sellAmountAfterFee });

        // It should emit a {FillOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.FillOrder({
            orderId: orderId,
            buyer: buyer,
            seller: users.seller,
            sellAmount: sellAmountAfterFee,
            buyAmount: buyAmountAfterFee,
            feeDeductedFromBuyerAmount: feeFromSellAmount,
            feeDeductedFromSellerAmount: feeFromBuyAmount
        });

        escrow.fillOrder(orderId, buyAmount);

        // It should mark the order as filled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.FILLED, "order.status");
        assertTrue(escrow.wasFilled(orderId), "order.wasFilled");
        assertFalse(escrow.wasCanceled(orderId), "order.wasCanceled");
    }
}
