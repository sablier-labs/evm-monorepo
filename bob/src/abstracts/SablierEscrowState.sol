// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierEscrowState } from "../interfaces/ISablierEscrowState.sol";
import { Errors } from "../libraries/Errors.sol";
import { Escrow } from "../types/Escrow.sol";

/// @title SablierEscrowState
/// @notice See the documentation in {ISablierEscrowState}.
abstract contract SablierEscrowState is ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrowState
    UD60x18 public constant override MAX_TRADE_FEE = UD60x18.wrap(0.02e18);

    /*//////////////////////////////////////////////////////////////////////////
                                   STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrowState
    address public override nativeToken;

    /// @inheritdoc ISablierEscrowState
    uint256 public override nextOrderId;

    /// @inheritdoc ISablierEscrowState
    UD60x18 public override tradeFee;

    /// @dev Orders mapped by order ID.
    mapping(uint256 orderId => Escrow.Order order) internal _orders;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initializes the state variables.
    /// @param initialTradeFee The initial trade fee percentage.
    constructor(UD60x18 initialTradeFee) {
        // Check: the trade fee is not greater than the maximum trade fee.
        _notTooHigh(initialTradeFee);

        // Set the next order ID to 1.
        nextOrderId = 1;

        // Set the initial trade fee.
        tradeFee = initialTradeFee;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that `orderId` does not reference a null order.
    modifier notNull(uint256 orderId) {
        _notNull(orderId);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                          USER-FACING READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierEscrowState
    function getBuyer(uint256 orderId) external view override notNull(orderId) returns (address buyer) {
        buyer = _orders[orderId].buyer;
    }

    /// @inheritdoc ISablierEscrowState
    function getBuyToken(uint256 orderId) external view override notNull(orderId) returns (IERC20 buyToken) {
        buyToken = _orders[orderId].buyToken;
    }

    /// @inheritdoc ISablierEscrowState
    function getExpiryTime(uint256 orderId) external view override notNull(orderId) returns (uint40 expiryTime) {
        expiryTime = _orders[orderId].expiryTime;
    }

    /// @inheritdoc ISablierEscrowState
    function getMinBuyAmount(uint256 orderId) external view override notNull(orderId) returns (uint128 minBuyAmount) {
        minBuyAmount = _orders[orderId].minBuyAmount;
    }

    /// @inheritdoc ISablierEscrowState
    function getSellAmount(uint256 orderId) external view override notNull(orderId) returns (uint128 sellAmount) {
        sellAmount = _orders[orderId].sellAmount;
    }

    /// @inheritdoc ISablierEscrowState
    function getSeller(uint256 orderId) external view override notNull(orderId) returns (address seller) {
        seller = _orders[orderId].seller;
    }

    /// @inheritdoc ISablierEscrowState
    function getSellToken(uint256 orderId) external view override notNull(orderId) returns (IERC20 sellToken) {
        sellToken = _orders[orderId].sellToken;
    }

    /// @inheritdoc ISablierEscrowState
    function statusOf(uint256 orderId) external view override notNull(orderId) returns (Escrow.Status status) {
        status = _statusOf(orderId);
    }

    /// @inheritdoc ISablierEscrowState
    function wasCanceled(uint256 orderId) external view override notNull(orderId) returns (bool result) {
        result = _orders[orderId].wasCanceled;
    }

    /// @inheritdoc ISablierEscrowState
    function wasFilled(uint256 orderId) external view override notNull(orderId) returns (bool result) {
        result = _orders[orderId].wasFilled;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if `newTradeFee` is greater than the maximum trade fee.
    function _notTooHigh(UD60x18 newTradeFee) internal pure {
        if (newTradeFee.gt(MAX_TRADE_FEE)) {
            revert Errors.SablierEscrowState_NewTradeFeeTooHigh(newTradeFee, MAX_TRADE_FEE);
        }
    }

    /// @dev Return the order status without performing a null check.
    function _statusOf(uint256 orderId) internal view returns (Escrow.Status) {
        if (_orders[orderId].wasFilled) {
            return Escrow.Status.FILLED;
        }
        if (_orders[orderId].wasCanceled) {
            return Escrow.Status.CANCELLED;
        }

        uint40 expiryTime = _orders[orderId].expiryTime;

        // Return EXPIRED if the order has an expiry timestamp and it has expired.
        if (expiryTime != 0 && block.timestamp >= expiryTime) {
            return Escrow.Status.EXPIRED;
        }

        return Escrow.Status.OPEN;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Reverts if `orderId` references a null order.
    function _notNull(uint256 orderId) private view {
        // An order is considered null if its seller address is zero.
        if (_orders[orderId].seller == address(0)) {
            revert Errors.SablierEscrowState_Null(orderId);
        }
    }
}
