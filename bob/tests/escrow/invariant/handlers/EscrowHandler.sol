// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";
import { ERC20Mock } from "@sablier/evm-utils/src/mocks/erc20/ERC20Mock.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { ISablierEscrow } from "src/interfaces/ISablierEscrow.sol";
import { Escrow } from "src/types/Escrow.sol";

import { Constants } from "../../utils/Constants.sol";
import { Store } from "../stores/Store.sol";

/// @notice Handler for the invariant tests of {SablierEscrow} contract.
contract EscrowHandler is Constants, StdCheats, BaseUtils, PRBMathUtils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum number of orders that can be created during invariant runs.
    uint256 internal constant MAX_ORDER_COUNT = 1000;

    /// @dev Maps function names to their call counts.
    mapping(string func => uint256 count) public calls;

    /// @dev Total calls across all handler functions.
    uint256 public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierEscrow public escrow;
    Store public store;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Simulates the passage of time. The time jump is kept under 40 days.
    modifier adjustTimestamp(uint256 timeJumpSeed) {
        uint256 timeJump = _bound(timeJumpSeed, 0, 40 days);
        skip(timeJump);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        calls[functionName]++;
        totalCalls++;
        _;
    }

    /// @dev Skip if no orders exist.
    modifier orderCountNotZero() {
        if (store.orderCount() == 0) return;
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(Store store_, ISablierEscrow escrow_) {
        store = store_;
        escrow = escrow_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function cancelOrder(uint256 timeJumpSeed)
        external
        instrument("cancelOrder")
        adjustTimestamp(timeJumpSeed)
        orderCountNotZero
    {
        // Pick a random order from the store.
        uint256 orderId = _fuzzOrderId();

        // Skip if order has been filled or canceled.
        if (escrow.wasFilled(orderId) || escrow.wasCanceled(orderId)) return;

        // Cancel the order.
        setMsgSender(escrow.getSeller(orderId));
        escrow.cancelOrder(orderId);
    }

    function createOrder(
        address seller,
        uint128 sellAmount,
        uint128 minBuyAmount,
        address buyer,
        uint40 expiryTime
    )
        external
        instrument("createOrder")
    {
        // Limit the number of orders.
        if (store.orderCount() >= MAX_ORDER_COUNT) return;

        // Exclude seller from being fuzzed as certain addresses.
        if (seller == address(0) || seller == address(escrow)) return;

        // Create new tokens or use existing ones.
        IERC20 sellToken = _getOrCreateToken();
        IERC20 buyToken = _getOrCreateToken();

        // Skip if tokens are same.
        if (sellToken == buyToken) return;

        // Bound buy and sell amounts.
        sellAmount = boundUint128(sellAmount, 1, 1000e18);
        minBuyAmount = boundUint128(minBuyAmount, 1, 1000e18);

        // If expiry time is not zero, bound it to reasonable range.
        if (expiryTime > 0) {
            expiryTime = boundUint40(expiryTime, getBlockTimestamp() + 10 days, getBlockTimestamp() + 100 days);
        }

        // If buyer is not zero, exclude it from being fuzzed as certain addresses.
        if (buyer != address(0) && buyer == address(escrow)) return;

        // Deal sell tokens to seller.
        deal({ token: address(sellToken), to: seller, give: sellAmount });

        // Set seller as the caller and approve escrow to spend sell tokens.
        setMsgSender(seller);
        sellToken.approve({ spender: address(escrow), value: sellAmount });

        // Create the order.
        uint256 orderId = escrow.createOrder({
            sellToken: sellToken,
            sellAmount: sellAmount,
            buyToken: buyToken,
            minBuyAmount: minBuyAmount,
            buyer: buyer,
            expiryTime: expiryTime
        });

        // Record in store.
        store.pushOrderId(orderId);
    }

    function fillOrder(
        uint256 timeJumpSeed,
        uint128 buyAmount,
        address buyer
    )
        external
        instrument("fillOrder")
        adjustTimestamp(timeJumpSeed)
        orderCountNotZero
    {
        // Pick a random order from the store.
        uint256 orderId = _fuzzOrderId();

        // Skip if order is not open.
        if (escrow.statusOf(orderId) != Escrow.Status.OPEN) return;

        // If designated buyer is set, use it.
        if (escrow.getBuyer(orderId) != address(0)) {
            buyer = escrow.getBuyer(orderId);
        }
        // Otherwise, exclude buyer from being fuzzed as certain addresses.
        else if (buyer == address(0) || buyer == address(escrow)) {
            return;
        }

        // Bound buy amount to reasonable range.
        buyAmount = boundUint128(buyAmount, escrow.getMinBuyAmount(orderId), escrow.getMinBuyAmount(orderId) * 2);

        // Deal buy tokens to buyer and fill the order.
        IERC20 buyToken = escrow.getBuyToken(orderId);
        deal({ token: address(buyToken), to: buyer, give: buyAmount });

        // Change caller to buyer and fill the order.
        setMsgSender(buyer);
        buyToken.approve({ spender: address(escrow), value: buyAmount });
        (
            uint128 amountToTransferToSeller,
            uint128 amountToTransferToBuyer,
            uint128 feeDeductedFromBuyerAmount,
            uint128 feeDeductedFromSellerAmount
        ) = escrow.fillOrder(orderId, buyAmount);

        // Update fill order metadata in the store.
        store.recordFill({
            orderId: orderId,
            data: Store.FillData(
                buyAmount,
                amountToTransferToSeller,
                amountToTransferToBuyer,
                feeDeductedFromBuyerAmount,
                feeDeductedFromSellerAmount
            )
        });
    }

    function setTradeFee(
        uint256 timeJumpSeed,
        UD60x18 newTradeFeeSeed
    )
        external
        instrument("setTradeFee")
        adjustTimestamp(timeJumpSeed)
    {
        // Limit fee changes to 10 per campaign.
        if (calls["setTradeFee"] > 10) return;

        // Bound the fee.
        UD60x18 newTradeFee = bound(newTradeFeeSeed, 0, MAX_TRADE_FEE);

        // Set comptroller as the caller.
        setMsgSender(address(escrow.comptroller()));
        escrow.setTradeFee(newTradeFee);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Returns an existing token or creates a new one.
    function _getOrCreateToken() private returns (IERC20) {
        // If no tokens exist or random number is even, create a new one.
        if (store.tokensCount() == 0 || vm.randomUint() % 2 == 0) {
            // Generate a random decimals value.
            uint8 decimals = uint8(vm.randomUint(2, 20));

            // Use next token index as the ID.
            string memory id = vm.toString(store.tokensCount());

            // Set the caller to the handler's address to deploy a new token.
            // setMsgSender(address(this));
            ERC20Mock token = new ERC20Mock(string.concat("Token", id), string.concat("TKN", id), decimals);

            // Update it in the store.
            store.pushToken(token);

            // Return the new token.
            return token;
        }

        // Otherwise, pick a random existing token.
        uint256 tokenIndex = vm.randomUint(0, store.tokensCount() - 1);

        // Return the token.
        return store.tokens(tokenIndex);
    }

    /// @dev Returns a random order ID from the store.
    function _fuzzOrderId() private view returns (uint256 orderId) {
        uint256 orderIndex = vm.randomUint(0, store.orderCount() - 1);
        orderId = store.orderIds(orderIndex);
    }
}
