// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Fork_Test } from "./Fork.t.sol";

contract Escrow_Fork_Test is Fork_Test {
    function setUp() public virtual override {
        Fork_Test.setUp();
    }

    struct Params {
        address seller;
        address buyer;
        uint128 sellAmount;
        uint128 buyAmount;
        uint40 expiryTime;
        uint40 timeJump;
    }

    function testForkFuzz_Escrow(Params memory params) external {
        vm.assume(params.seller != address(0) && params.buyer != address(0));
        vm.assume(params.seller != params.buyer);
        vm.assume(params.seller != address(escrow) && params.buyer != address(escrow));
        vm.assume(params.seller != address(comptroller) && params.buyer != address(comptroller));

        assumeNoBlacklisted(address(USDC), params.seller);
        assumeNoBlacklisted(address(USDC), params.buyer);

        params.sellAmount = boundUint128(params.sellAmount, 1, MAX_UINT128 - 1);
        params.buyAmount = boundUint128(params.buyAmount, 1, MAX_UINT128 - 1);

        // Set the expiry time to be between 1 second and 5 years from the current block timestamp.
        params.expiryTime = boundUint40(params.expiryTime, getBlockTimestamp() + 1, getBlockTimestamp() + 5 * 365 days);

        // Bound timeJump so that the order is still OPEN when we cancel and fill.
        params.timeJump = boundUint40(params.timeJump, 0, params.expiryTime - getBlockTimestamp() - 1);

        /*//////////////////////////////////////////////////////////////////////////
                                    SETUP: DEAL AND APPROVE
        //////////////////////////////////////////////////////////////////////////*/

        // Seller needs USDC for 2 orders.
        deal(address(USDC), params.seller, uint256(params.sellAmount) * 2);
        setMsgSender(params.seller);
        USDC.approve(address(escrow), uint256(params.sellAmount) * 2);

        // Buyer needs WETH to fill 1 order.
        deal(address(WETH), params.buyer, uint256(params.buyAmount));
        setMsgSender(params.buyer);
        WETH.approve(address(escrow), uint256(params.buyAmount));

        /*//////////////////////////////////////////////////////////////////////////
                                CREATE ORDER 1 (TO CANCEL)
        //////////////////////////////////////////////////////////////////////////*/

        setMsgSender(params.seller);
        uint256 expectedOrderId1 = escrow.nextOrderId();

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: USDC, from: params.seller, to: address(escrow), value: params.sellAmount });

        // It should emit a {Transfer} event.
        vm.expectEmit({ emitter: address(USDC) });
        emit IERC20.Transfer(params.seller, address(escrow), params.sellAmount);

        // It should emit a {CreateOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId1,
            seller: params.seller,
            buyer: params.buyer,
            sellToken: USDC,
            buyToken: WETH,
            sellAmount: params.sellAmount,
            minBuyAmount: params.buyAmount,
            expiryTime: params.expiryTime
        });

        uint256 orderToCancel = escrow.createOrder({
            sellToken: USDC,
            sellAmount: params.sellAmount,
            buyToken: WETH,
            minBuyAmount: params.buyAmount,
            buyer: params.buyer,
            expiryTime: params.expiryTime
        });

        // It should create the order.
        assertEq(orderToCancel, expectedOrderId1, "orderToCancel id");
        assertEq(escrow.getSeller(orderToCancel), params.seller, "orderToCancel.seller");
        assertEq(escrow.getBuyer(orderToCancel), params.buyer, "orderToCancel.buyer");
        assertEq(escrow.getSellToken(orderToCancel), USDC, "orderToCancel.sellToken");
        assertEq(escrow.getBuyToken(orderToCancel), WETH, "orderToCancel.buyToken");
        assertEq(escrow.getSellAmount(orderToCancel), params.sellAmount, "orderToCancel.sellAmount");
        assertEq(escrow.getMinBuyAmount(orderToCancel), params.buyAmount, "orderToCancel.minBuyAmount");
        assertEq(escrow.getExpiryTime(orderToCancel), params.expiryTime, "orderToCancel.expiryTime");
        assertEq(escrow.statusOf(orderToCancel), Escrow.Status.OPEN, "orderToCancel.status");
        assertFalse(escrow.wasCanceled(orderToCancel), "orderToCancel.wasCanceled");
        assertFalse(escrow.wasFilled(orderToCancel), "orderToCancel.wasFilled");

        /*//////////////////////////////////////////////////////////////////////////
                                CREATE ORDER 2 (TO FILL)
        //////////////////////////////////////////////////////////////////////////*/

        uint256 expectedOrderId2 = escrow.nextOrderId();

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: USDC, from: params.seller, to: address(escrow), value: params.sellAmount });

        // It should emit a {Transfer} event.
        vm.expectEmit({ emitter: address(USDC) });
        emit IERC20.Transfer(params.seller, address(escrow), params.sellAmount);

        // It should emit a {CreateOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CreateOrder({
            orderId: expectedOrderId2,
            seller: params.seller,
            buyer: params.buyer,
            sellToken: USDC,
            buyToken: WETH,
            sellAmount: params.sellAmount,
            minBuyAmount: params.buyAmount,
            expiryTime: params.expiryTime
        });

        uint256 orderToFill = escrow.createOrder({
            sellToken: USDC,
            sellAmount: params.sellAmount,
            buyToken: WETH,
            minBuyAmount: params.buyAmount,
            buyer: params.buyer,
            expiryTime: params.expiryTime
        });

        // It should create the order.
        assertEq(orderToFill, expectedOrderId2, "orderToFill id");
        assertEq(escrow.statusOf(orderToFill), Escrow.Status.OPEN, "orderToFill.status");
        assertEq(escrow.nextOrderId(), expectedOrderId2 + 1, "nextOrderId");

        /*//////////////////////////////////////////////////////////////////////////
                                        TIME JUMP
        //////////////////////////////////////////////////////////////////////////*/

        vm.warp(getBlockTimestamp() + params.timeJump);

        /*//////////////////////////////////////////////////////////////////////////
                                      CANCEL ORDER 1
        //////////////////////////////////////////////////////////////////////////*/

        // It should emit a {Transfer} event.
        vm.expectEmit({ emitter: address(USDC) });
        emit IERC20.Transfer(address(escrow), params.seller, params.sellAmount);

        // It should emit a {CancelOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.CancelOrder({
            orderId: orderToCancel,
            seller: params.seller,
            sellAmount: params.sellAmount
        });

        escrow.cancelOrder(orderToCancel);

        // It should cancel the order.
        assertEq(escrow.statusOf(orderToCancel), Escrow.Status.CANCELLED, "orderToCancel.status after cancel");
        assertTrue(escrow.wasCanceled(orderToCancel), "orderToCancel.wasCanceled after cancel");
        assertFalse(escrow.wasFilled(orderToCancel), "orderToCancel.wasFilled after cancel");

        /*//////////////////////////////////////////////////////////////////////////
                                       FILL ORDER 2
        //////////////////////////////////////////////////////////////////////////*/

        setMsgSender(params.buyer);

        UD60x18 currentTradeFee = escrow.tradeFee();
        uint128 feeFromSellAmount = ud(params.sellAmount).mul(currentTradeFee).intoUint128();
        uint128 feeFromBuyAmount = ud(params.buyAmount).mul(currentTradeFee).intoUint128();
        uint128 sellAmountAfterFee = params.sellAmount - feeFromSellAmount;
        uint128 buyAmountAfterFee = params.buyAmount - feeFromBuyAmount;

        // It should perform the ERC-20 transfers.
        if (feeFromBuyAmount > 0) {
            expectCallToTransferFrom({
                token: WETH,
                from: params.buyer,
                to: address(comptroller),
                value: feeFromBuyAmount
            });
        }
        if (feeFromSellAmount > 0) {
            expectCallToTransfer({ token: USDC, to: address(comptroller), value: feeFromSellAmount });
        }
        expectCallToTransferFrom({ token: WETH, from: params.buyer, to: params.seller, value: buyAmountAfterFee });
        expectCallToTransfer({ token: USDC, to: params.buyer, value: sellAmountAfterFee });

        // It should emit {Transfer} events (in emission order).
        if (feeFromBuyAmount > 0) {
            vm.expectEmit({ emitter: address(WETH) });
            emit IERC20.Transfer(params.buyer, address(comptroller), feeFromBuyAmount);
        }
        if (feeFromSellAmount > 0) {
            vm.expectEmit({ emitter: address(USDC) });
            emit IERC20.Transfer(address(escrow), address(comptroller), feeFromSellAmount);
        }
        vm.expectEmit({ emitter: address(WETH) });
        emit IERC20.Transfer(params.buyer, params.seller, buyAmountAfterFee);
        vm.expectEmit({ emitter: address(USDC) });
        emit IERC20.Transfer(address(escrow), params.buyer, sellAmountAfterFee);

        // It should emit a {FillOrder} event.
        vm.expectEmit({ emitter: address(escrow) });
        emit ISablierEscrow.FillOrder({
            orderId: orderToFill,
            buyer: params.buyer,
            seller: params.seller,
            sellAmount: sellAmountAfterFee,
            buyAmount: buyAmountAfterFee,
            feeDeductedFromBuyerAmount: feeFromSellAmount,
            feeDeductedFromSellerAmount: feeFromBuyAmount
        });

        escrow.fillOrder(orderToFill, params.buyAmount);

        // It should fill the order.
        assertEq(escrow.statusOf(orderToFill), Escrow.Status.FILLED, "orderToFill.status after fill");
        assertTrue(escrow.wasFilled(orderToFill), "orderToFill.wasFilled after fill");
        assertFalse(escrow.wasCanceled(orderToFill), "orderToFill.wasCanceled after fill");
    }
}
