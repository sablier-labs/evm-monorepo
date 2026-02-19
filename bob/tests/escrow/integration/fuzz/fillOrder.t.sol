// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "./../Integration.t.sol";

contract FillOrder_Integration_Fuzz_Test is Integration_Test {
    /// @dev Designated buyer, default trade fee (1%).
    function testFuzz_FillOrder(
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint128 buyAmount,
        uint40 expiryTime,
        uint40 timeJump
    )
        external
    {
        _testFillOrder({
            sellAmount: sellAmount,
            minBuyAmount: minBuyAmount,
            buyAmount: buyAmount,
            expiryTime: expiryTime,
            timeJump: timeJump,
            buyer: users.buyer,
            fee: DEFAULT_TRADE_FEE
        });
    }

    /// @dev Designated buyer, zero trade fee — exercises the `if (currentTradeFee > 0)` skip branch.
    function testFuzz_FillOrder_GivenTradeFeeZero(
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint128 buyAmount,
        uint40 expiryTime,
        uint40 timeJump
    )
        external
    {
        // Set the trade fee to zero before creating the order.
        setMsgSender(address(comptroller));
        escrow.setTradeFee(ZERO);

        _testFillOrder({
            sellAmount: sellAmount,
            minBuyAmount: minBuyAmount,
            buyAmount: buyAmount,
            expiryTime: expiryTime,
            timeJump: timeJump,
            buyer: users.buyer,
            fee: ZERO
        });
    }

    /// @dev Open order (buyer = address(0)), default trade fee — exercises the open-order access path.
    function testFuzz_FillOrder_GivenOpenOrder(
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint128 buyAmount,
        uint40 expiryTime,
        uint40 timeJump
    )
        external
    {
        _testFillOrder({
            sellAmount: sellAmount,
            minBuyAmount: minBuyAmount,
            buyAmount: buyAmount,
            expiryTime: expiryTime,
            timeJump: timeJump,
            buyer: address(0),
            fee: DEFAULT_TRADE_FEE
        });
    }

    /// @dev Exercises the revert when filling an expired order.
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

    /*//////////////////////////////////////////////////////////////////////////
                                    PRIVATE HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testFillOrder(
        uint128 sellAmount,
        uint128 minBuyAmount,
        uint128 buyAmount,
        uint40 expiryTime,
        uint40 timeJump,
        address buyer,
        UD60x18 fee
    )
        private
    {
        // Bound amounts.
        sellAmount = boundUint128(sellAmount, 1, MAX_UINT128);
        minBuyAmount = boundUint128(minBuyAmount, 1, MAX_UINT128);
        buyAmount = boundUint128(buyAmount, minBuyAmount, MAX_UINT128);

        // Bound timing: expiryTime in future, timeJump stays before expiry so order remains OPEN.
        expiryTime = boundUint40(expiryTime, getBlockTimestamp() + 1, getBlockTimestamp() + 5 * 365 days);
        uint40 maxJump = expiryTime - getBlockTimestamp() - 1;
        timeJump = boundUint40(timeJump, 0, maxJump);

        // Deal tokens.
        deal({ token: address(sellToken), to: users.seller, give: sellAmount });
        deal({ token: address(buyToken), to: users.buyer, give: buyAmount });

        // Create the order as seller.
        setMsgSender(users.seller);
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: sellAmount,
            buyToken: buyToken,
            minBuyAmount: minBuyAmount,
            buyer: buyer,
            expiryTime: expiryTime
        });

        // Warp forward (stays before expiry).
        vm.warp(getBlockTimestamp() + timeJump);

        // Compute fees.
        uint128 feeFromSellAmount = ud(sellAmount).mul(fee).intoUint128();
        uint128 feeFromBuyAmount = ud(buyAmount).mul(fee).intoUint128();
        uint128 sellAmountAfterFee = sellAmount - feeFromSellAmount;
        uint128 buyAmountAfterFee = buyAmount - feeFromBuyAmount;

        // Switch to buyer.
        setMsgSender(users.buyer);

        // Expect ERC-20 transfer calls.
        if (feeFromBuyAmount > 0) {
            expectCallToTransferFrom({
                token: buyToken,
                from: users.buyer,
                to: address(comptroller),
                value: feeFromBuyAmount
            });
        }
        if (feeFromSellAmount > 0) {
            expectCallToTransfer({ token: sellToken, to: address(comptroller), value: feeFromSellAmount });
        }
        expectCallToTransferFrom({ token: buyToken, from: users.buyer, to: users.seller, value: buyAmountAfterFee });
        expectCallToTransfer({ token: sellToken, to: users.buyer, value: sellAmountAfterFee });

        // It should emit a {FillOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.FillOrder({
            orderId: orderId,
            buyer: users.buyer,
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
