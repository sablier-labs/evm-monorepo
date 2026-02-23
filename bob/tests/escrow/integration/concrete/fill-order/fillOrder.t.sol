// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract FillOrder_Integration_Concrete_Test is Integration_Test {
    /// @dev Variable to store the order ID of an order without any buyer.
    uint256 internal orderWithoutAnyBuyer;

    function setUp() public override {
        Integration_Test.setUp();

        // Create an order without any buyer.
        orderWithoutAnyBuyer = createDefaultOrder({ buyer: address(0) });

        // Set the buyer as the default caller for the tests.
        setMsgSender(users.buyer);
    }

    function test_RevertGiven_Null() external {
        // It should revert.
        expectRevert_Null(abi.encodeCall(escrow.fillOrder, (nullOrderId, MIN_BUY_AMOUNT)));
    }

    function test_RevertGiven_Canceled() external givenNotNull {
        // Cancel the order.
        setMsgSender(users.seller);
        escrow.cancelOrder(defaultOrderId);

        // It should revert.
        setMsgSender(users.buyer);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrow_OrderNotOpen.selector, defaultOrderId, Escrow.Status.CANCELLED)
        );
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);
    }

    function test_RevertGiven_Filled() external givenNotNull {
        // Fill the order.
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrow_OrderNotOpen.selector, defaultOrderId, Escrow.Status.FILLED)
        );
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);
    }

    function test_RevertGiven_Expired() external givenNotNull {
        // Warp past expiry.
        vm.warp(ORDER_EXPIRY_TIME + 1);

        // It should revert.
        setMsgSender(users.buyer);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrow_OrderNotOpen.selector, defaultOrderId, Escrow.Status.EXPIRED)
        );
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);
    }

    function test_RevertWhen_CallerNotDesignatedBuyer() external givenNotNull givenOpen givenOrderWithDesignatedBuyer {
        setMsgSender(users.alice);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierEscrow_CallerNotAuthorized.selector, defaultOrderId, users.alice, users.buyer
            )
        );
        escrow.fillOrder(defaultOrderId, MIN_BUY_AMOUNT);
    }

    function test_WhenCallerDesignatedBuyer() external givenNotNull givenOpen givenOrderWithDesignatedBuyer {
        // It should fill the order.
        _testFillOrder({ orderId: defaultOrderId, tradeFee: DEFAULT_TRADE_FEE });
    }

    function test_RevertWhen_BuyAmountLessThanMinBuyAmount()
        external
        givenNotNull
        givenOpen
        givenOrderWithoutDesignatedBuyer
    {
        uint128 buyAmount = MIN_BUY_AMOUNT - 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierEscrow_InsufficientBuyAmount.selector, buyAmount, MIN_BUY_AMOUNT)
        );
        escrow.fillOrder(orderWithoutAnyBuyer, buyAmount);
    }

    function test_GivenTradeFeeZero()
        external
        givenNotNull
        givenOpen
        givenOrderWithoutDesignatedBuyer
        whenBuyAmountNotLessThanMinBuyAmount
    {
        // Set the trade fee to zero.
        setMsgSender(address(comptroller));
        escrow.setTradeFee(ZERO);

        // It should fill the order.
        setMsgSender(users.buyer);
        _testFillOrder({ orderId: orderWithoutAnyBuyer, tradeFee: ZERO });
    }

    function test_GivenTradeFeeNotZero()
        external
        givenNotNull
        givenOpen
        givenOrderWithoutDesignatedBuyer
        whenBuyAmountNotLessThanMinBuyAmount
    {
        _testFillOrder({ orderId: orderWithoutAnyBuyer, tradeFee: DEFAULT_TRADE_FEE });
    }

    /// @dev Private shared logic.
    function _testFillOrder(uint256 orderId, UD60x18 tradeFee) private {
        uint128 feeFromSellAmount = ud(SELL_AMOUNT).mul(tradeFee).intoUint128();
        uint128 feeFromBuyAmount = ud(MIN_BUY_AMOUNT).mul(tradeFee).intoUint128();
        uint128 sellAmountAfterFee = SELL_AMOUNT - feeFromSellAmount;
        uint128 buyAmountAfterFee = MIN_BUY_AMOUNT - feeFromBuyAmount;

        // It should perform the ERC-20 transfers.
        if (feeFromSellAmount > 0) {
            expectCallToTransfer({ token: sellToken, to: address(comptroller), value: feeFromSellAmount });
        }
        expectCallToTransfer({ token: sellToken, to: users.buyer, value: sellAmountAfterFee });
        if (feeFromBuyAmount > 0) {
            expectCallToTransferFrom({
                token: buyToken,
                from: users.buyer,
                to: address(comptroller),
                value: feeFromBuyAmount
            });
        }
        expectCallToTransferFrom({ token: buyToken, from: users.buyer, to: users.seller, value: buyAmountAfterFee });

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

        escrow.fillOrder(orderId, MIN_BUY_AMOUNT);

        // It should update the order status to filled.
        assertEq(escrow.statusOf(orderId), Escrow.Status.FILLED, "order.status");
        assertTrue(escrow.wasFilled(orderId), "order.wasFilled");
    }
}
