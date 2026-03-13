// SPDX-License-Identifier: GPL-3.0-or-later
// SablierEscrow.spec — Certora CVL specification for SablierEscrow
//
// Covers:
//   Inv 33: Order state irreversibility (FILLED/CANCELLED/EXPIRED -> OPEN impossible)
//   Inv 34: Fill once — wasFilled true stays true
//   Inv 35: Cancel only when OPEN (or EXPIRED per code)
//   Inv 37: tradeFee <= MAX_TRADE_FEE
//   Inv 38: Private order buyer enforcement
//   Inv 39: nextOrderId monotonic
//   Inv 40: Order immutability after creation
//   Inv 41: wasFilled/wasCanceled monotonic booleans
//   Inv 42: sellAmount conservation on fill
//   Inv 43: buyAmount conservation on fill
//   Inv 44: Only seller can cancel order
//   Inv 45: Seller receives >= minBuyAmount (expected FAIL, L-8)
//   Inv 46: nativeToken never accepted as sellToken or buyToken
//   Inv 47 (partial): nativeToken set-once
//   Inv 48 (partial): comptroller-only admin functions
//   Inv 50: wasFilled and wasCanceled mutually exclusive

methods {
    // Escrow state getters — envfree (only types that map cleanly to CVL)
    function nextOrderId()                    external returns (uint256)   envfree;
    function nativeToken()                    external returns (address)   envfree;
    function getSeller(uint256)               external returns (address)   envfree;
    function getBuyer(uint256)                external returns (address)   envfree;
    function getSellToken(uint256)            external returns (address)   envfree;
    function getBuyToken(uint256)             external returns (address)   envfree;
    function getSellAmount(uint256)           external returns (uint128)   envfree;
    function getMinBuyAmount(uint256)         external returns (uint128)   envfree;
    function getExpiryTime(uint256)           external returns (uint40)    envfree;
    function wasFilled(uint256)               external returns (bool)      envfree;
    function wasCanceled(uint256)             external returns (bool)      envfree;
    function comptroller()                    external returns (address)   envfree;

    // Note: statusOf returns Escrow.Status (enum), tradeFee/MAX_TRADE_FEE return UD60x18 (UDVT)
    // These are NOT declared envfree due to CVL type-merge issues with enums and UDVTs.
    // They must be called with an env parameter.

    // ERC-20 token interactions — NONDET summary (conservative havoc)
    function _.transferFrom(address, address, uint256) external => NONDET;
    function _.transfer(address, uint256)              external => NONDET;
    function _.balanceOf(address)                      external => NONDET;
    function _.allowance(address, address)             external => NONDET;
}

// Escrow.Status enum values: CANCELLED=0, EXPIRED=1, FILLED=2, OPEN=3
definition CANCELLED() returns uint8 = 0;
definition EXPIRED()   returns uint8 = 1;
definition FILLED()    returns uint8 = 2;
definition OPEN()      returns uint8 = 3;

/*//////////////////////////////////////////////////////////////////////////
                INV 33: Order state irreversibility
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: Terminal states cannot revert to OPEN
/// @notice Once an order is FILLED or CANCELLED, it cannot become OPEN again
rule orderStateIrreversibility(method f, uint256 orderId) filtered {
    f -> !f.isView
} {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";

    // wasFilled or wasCanceled means the order is in a terminal state
    bool filledBefore = wasFilled(orderId);
    bool canceledBefore = wasCanceled(orderId);
    require filledBefore || canceledBefore,
        "safe: order must be in terminal state (filled or canceled)";

    env e;
    calldataarg args;
    f(e, args);

    bool filledAfter = wasFilled(orderId);
    bool canceledAfter = wasCanceled(orderId);

    // Terminal flags must remain set (can't go back to OPEN)
    assert filledBefore => filledAfter,
        "Inv 33: wasFilled reverted to false";
    assert canceledBefore => canceledAfter,
        "Inv 33: wasCanceled reverted to false";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 34: Fill once — wasFilled stays true
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: wasFilled is monotonic (once true, never false)
rule wasFilledMonotonic(method f, uint256 orderId) filtered {
    f -> !f.isView
} {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    bool filledBefore = wasFilled(orderId);
    require filledBefore == true,
        "safe: order must already be filled";

    env e;
    calldataarg args;
    f(e, args);

    bool filledAfter = wasFilled(orderId);

    assert filledAfter == true,
        "Inv 34: wasFilled went from true to false";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 35: Cancel only when OPEN (or EXPIRED per code)
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: cancelOrder reverts if order is FILLED
rule cancelRevertsIfFilled(uint256 orderId) {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    require wasFilled(orderId) == true,
        "safe: order must already be filled";

    env e;
    cancelOrder@withrevert(e, orderId);

    assert lastReverted,
        "Inv 35: cancelOrder should revert for filled orders";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 37: tradeFee <= MAX_TRADE_FEE
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: tradeFee never exceeds MAX_TRADE_FEE after any state change
/// @notice Using a rule instead of invariant since tradeFee/MAX_TRADE_FEE return UD60x18
rule tradeFeeNotTooHigh(method f) filtered {
    f -> !f.isView
} {
    env e1;
    uint256 feeBefore = tradeFee(e1);
    uint256 maxFee = MAX_TRADE_FEE(e1);
    require feeBefore <= maxFee,
        "safe: initial state satisfies the fee bound (inductive hypothesis)";

    env e2;
    calldataarg args;
    f(e2, args);

    env e3;
    uint256 feeAfter = tradeFee(e3);

    assert feeAfter <= maxFee,
        "Inv 37: tradeFee exceeds MAX_TRADE_FEE";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 38: Private order buyer enforcement
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: fillOrder reverts if private order and caller is not the designated buyer
rule privateOrderBuyerEnforcement(uint256 orderId, uint128 buyAmount) {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    address designatedBuyer = getBuyer(orderId);
    require designatedBuyer != 0,
        "safe: order must be private (has designated buyer)";

    // Order must be in OPEN state (not filled, not canceled, not expired)
    require wasFilled(orderId) == false,
        "safe: order must not be filled";
    require wasCanceled(orderId) == false,
        "safe: order must not be canceled";

    env e;
    require e.msg.sender != designatedBuyer,
        "safe: caller must not be the designated buyer";

    fillOrder@withrevert(e, orderId, buyAmount);

    assert lastReverted,
        "Inv 38: fillOrder should revert for unauthorized buyer on private order";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 39: nextOrderId monotonic
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: nextOrderId never decreases
/// @notice createOrder uses unchecked { nextOrderId = orderId + 1 }, so we exclude the
///         physically-unreachable max_uint256 state to prevent the prover from finding a
///         wrap-around counterexample.
rule nextOrderIdMonotonic(method f) filtered {
    f -> !f.isView
} {
    uint256 idBefore = nextOrderId();
    require idBefore < max_uint256,
        "safe: 2^256-1 orders is physically unreachable";

    env e;
    calldataarg args;
    f(e, args);

    uint256 idAfter = nextOrderId();

    assert idAfter >= idBefore,
        "Inv 39: nextOrderId decreased";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 40: Order immutability after creation
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: Order core fields never change after creation
rule orderFieldsImmutable(method f, uint256 orderId) filtered {
    f -> !f.isView
} {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";

    address sellerBefore     = getSeller(orderId);
    address buyerBefore      = getBuyer(orderId);
    address sellTokenBefore  = getSellToken(orderId);
    address buyTokenBefore   = getBuyToken(orderId);
    uint128 sellAmountBefore = getSellAmount(orderId);
    uint128 minBuyBefore     = getMinBuyAmount(orderId);
    uint40  expiryBefore     = getExpiryTime(orderId);

    env e;
    calldataarg args;
    f(e, args);

    assert getSeller(orderId)    == sellerBefore,
        "Inv 40: seller changed";
    assert getBuyer(orderId)     == buyerBefore,
        "Inv 40: buyer changed";
    assert getSellToken(orderId) == sellTokenBefore,
        "Inv 40: sellToken changed";
    assert getBuyToken(orderId)  == buyTokenBefore,
        "Inv 40: buyToken changed";
    assert getSellAmount(orderId) == sellAmountBefore,
        "Inv 40: sellAmount changed";
    assert getMinBuyAmount(orderId) == minBuyBefore,
        "Inv 40: minBuyAmount changed";
    assert getExpiryTime(orderId) == expiryBefore,
        "Inv 40: expiryTime changed";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 41: wasFilled/wasCanceled monotonic
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: wasCanceled is monotonic (once true, never false)
rule wasCanceledMonotonic(method f, uint256 orderId) filtered {
    f -> !f.isView
} {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    bool canceledBefore = wasCanceled(orderId);
    require canceledBefore == true,
        "safe: order must already be canceled";

    env e;
    calldataarg args;
    f(e, args);

    bool canceledAfter = wasCanceled(orderId);

    assert canceledAfter == true,
        "Inv 41: wasCanceled went from true to false";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 42 & 43: Conservation on fill
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: sellAmount conservation — amountToTransferToBuyer + fee == sellAmount
/// @notice On fillOrder, the sell side is split between buyer transfer and fee
rule sellAmountConservationOnFill(uint256 orderId, uint128 buyAmount) {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    uint128 sellAmount = getSellAmount(orderId);

    env e;
    uint128 amountToTransferToSeller;
    uint128 amountToTransferToBuyer;
    uint128 feeDeductedFromBuyerAmount;
    uint128 feeDeductedFromSellerAmount;
    (amountToTransferToSeller, amountToTransferToBuyer, feeDeductedFromBuyerAmount, feeDeductedFromSellerAmount) =
        fillOrder(e, orderId, buyAmount);

    // Sell side conservation: buyer gets (sellAmount - fee)
    assert to_mathint(amountToTransferToBuyer) + to_mathint(feeDeductedFromBuyerAmount) == to_mathint(sellAmount),
        "Inv 42: sell amount not conserved on fill";
}

/// @title Rule: buyAmount conservation — amountToTransferToSeller + fee == buyAmount
/// @notice On fillOrder, the buy side is split between seller transfer and fee
rule buyAmountConservationOnFill(uint256 orderId, uint128 buyAmount) {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";

    env e;
    uint128 amountToTransferToSeller;
    uint128 amountToTransferToBuyer;
    uint128 feeDeductedFromBuyerAmount;
    uint128 feeDeductedFromSellerAmount;
    (amountToTransferToSeller, amountToTransferToBuyer, feeDeductedFromBuyerAmount, feeDeductedFromSellerAmount) =
        fillOrder(e, orderId, buyAmount);

    // Buy side conservation: seller gets (buyAmount - fee)
    assert to_mathint(amountToTransferToSeller) + to_mathint(feeDeductedFromSellerAmount) == to_mathint(buyAmount),
        "Inv 43: buy amount not conserved on fill";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 44: Only seller can cancel order
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: only the seller who created the order can cancel it
/// @notice cancelOrder must revert if msg.sender is not the seller
rule onlySellerCanCancel(uint256 orderId) {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    address seller = getSeller(orderId);

    env e;
    require e.msg.sender != seller,
        "safe: caller must not be the seller";

    cancelOrder@withrevert(e, orderId);

    assert lastReverted,
        "Inv 44: cancelOrder succeeded for non-seller caller";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 45: Seller receives >= minBuyAmount (expected FAIL)
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: seller receives at least minBuyAmount after fee deduction — EXPECTED FAIL
/// @notice The final buyToken amount received by the seller must be >= minBuyAmount.
///         Expected to FAIL because the trade fee is deducted from the buy amount,
///         so amountToTransferToSeller = buyAmount - fee, which can be less than minBuyAmount
///         when buyAmount equals minBuyAmount and the fee is non-zero.
rule sellerReceivesAtLeastMinBuyAmount(uint256 orderId, uint128 buyAmount) {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";
    uint128 minBuy = getMinBuyAmount(orderId);

    env e;
    uint128 amountToTransferToSeller;
    uint128 amountToTransferToBuyer;
    uint128 feeDeductedFromBuyerAmount;
    uint128 feeDeductedFromSellerAmount;
    (amountToTransferToSeller, amountToTransferToBuyer,
     feeDeductedFromBuyerAmount, feeDeductedFromSellerAmount) =
        fillOrder(e, orderId, buyAmount);

    assert to_mathint(amountToTransferToSeller) >= to_mathint(minBuy),
        "Inv 45: seller received less than minBuyAmount after fee deduction";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 47 (partial): nativeToken set-once
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: once nativeToken is set to non-zero, it cannot change
/// @notice setNativeToken is filtered because it reverts when nativeToken != 0 (set-once pattern).
///         Its access control is verified by setNativeTokenOnlyComptroller.
rule nativeTokenSetOnce(method f) filtered {
    f -> !f.isView && f.selector != sig:setNativeToken(address).selector
} {
    address nativeBefore = nativeToken();
    require nativeBefore != 0,
        "safe: nativeToken must already be set";

    env e;
    calldataarg args;
    f(e, args);

    address nativeAfter = nativeToken();

    assert nativeAfter == nativeBefore,
        "Inv 47: nativeToken changed after being set";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 48 (partial): comptroller-only admin
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: setTradeFee only callable by comptroller
rule setTradeFeeOnlyComptroller(uint256 newFee) {
    address comp = comptroller();

    env e;
    require e.msg.sender != comp,
        "safe: caller must not be comptroller";

    setTradeFee@withrevert(e, newFee);

    assert lastReverted,
        "Inv 48: setTradeFee called by non-comptroller";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 50: wasFilled and wasCanceled mutually exclusive
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: wasFilled and wasCanceled can never both be true for the same order
/// @notice Inductive: assume mutual exclusion holds before any function call, assert it holds after
rule filledAndCanceledMutuallyExclusive(method f, uint256 orderId) filtered {
    f -> !f.isView
} {
    require orderId < nextOrderId(),
        "safe: only valid order IDs";

    bool filledBefore = wasFilled(orderId);
    bool canceledBefore = wasCanceled(orderId);
    require !(filledBefore && canceledBefore),
        "safe: inductive hypothesis — mutual exclusion holds before call";

    env e;
    calldataarg args;
    f(e, args);

    bool filledAfter = wasFilled(orderId);
    bool canceledAfter = wasCanceled(orderId);

    assert !(filledAfter && canceledAfter),
        "Inv 50: wasFilled and wasCanceled are both true for the same order";
}

/// @title Rule: setNativeToken only callable by comptroller
rule setNativeTokenOnlyComptroller(address newNative) {
    address comp = comptroller();

    env e;
    require e.msg.sender != comp,
        "safe: caller must not be comptroller";

    setNativeToken@withrevert(e, newNative);

    assert lastReverted,
        "Inv 48: setNativeToken called by non-comptroller";
}

/*//////////////////////////////////////////////////////////////////////////
                INV 46: nativeToken never accepted as order tokens
//////////////////////////////////////////////////////////////////////////*/

/// @title Rule: createOrder reverts if sellToken is nativeToken
/// @notice Native tokens as defined by nativeToken must never be accepted as order tokens.
///         SablierEscrow.createOrder checks `if (address(sellToken) == nativeToken) revert`.
rule createOrderRejectsNativeSellToken(
    address sellToken, uint128 sellAmount, address buyToken, uint128 minBuyAmount, address buyer, uint40 expiryTime
) {
    address native = nativeToken();
    require native != 0,
        "safe: nativeToken must be set for the check to be meaningful";
    require sellToken == native,
        "safe: attempting to use native token as sell token";

    env e;
    createOrder@withrevert(e, sellToken, sellAmount, buyToken, minBuyAmount, buyer, expiryTime);

    assert lastReverted,
        "Inv 46: createOrder accepted native token as sell token";
}

/// @title Rule: createOrder reverts if buyToken is nativeToken
/// @notice SablierEscrow.createOrder checks `if (address(buyToken) == nativeToken) revert`.
rule createOrderRejectsNativeBuyToken(
    address sellToken, uint128 sellAmount, address buyToken, uint128 minBuyAmount, address buyer, uint40 expiryTime
) {
    address native = nativeToken();
    require native != 0,
        "safe: nativeToken must be set for the check to be meaningful";
    require sellToken != native,
        "safe: sellToken is not native (avoid earlier revert)";
    require sellToken != 0,
        "safe: sellToken is not zero (avoid earlier revert)";
    require buyToken == native,
        "safe: attempting to use native token as buy token";

    env e;
    createOrder@withrevert(e, sellToken, sellAmount, buyToken, minBuyAmount, buyer, expiryTime);

    assert lastReverted,
        "Inv 46: createOrder accepted native token as buy token";
}
