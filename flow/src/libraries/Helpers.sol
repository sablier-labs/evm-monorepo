// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Broker } from "./../types/DataTypes.sol";
import { Errors } from "./Errors.sol";

/// @title Helpers
/// @notice Library with helper functions in {SablierFlow} contract.
library Helpers {
    /// @dev Calculate the fee amount and the net amount after subtracting the fee, based on the `fee` percentage.
    function calculateAmountsFromFee(
        uint128 totalAmount,
        UD60x18 fee
    )
        internal
        pure
        returns (uint128 feeAmount, uint128 netAmount)
    {
        // Calculate the fee amount based on the fee percentage.
        feeAmount = ud(totalAmount).mul(fee).intoUint128();

        // Calculate the net amount after subtracting the fee from the total amount.
        netAmount = totalAmount - feeAmount;
    }

    /// @dev Checks the `Broker` parameter, and then calculates the broker fee amount and the deposit amount from the
    /// total amount.
    function checkAndCalculateBrokerFee(
        uint128 totalAmount,
        Broker memory broker,
        UD60x18 maxFee
    )
        internal
        pure
        returns (uint128 brokerFeeAmount, uint128 depositAmount)
    {
        // Check: the broker's fee is not greater than `MAX_FEE`.
        if (broker.fee.gt(maxFee)) {
            revert Errors.SablierFlow_BrokerFeeTooHigh(broker.fee, maxFee);
        }

        // Check: the broker recipient is not the zero address.
        if (broker.account == address(0)) {
            revert Errors.SablierFlow_BrokerAddressZero();
        }

        // Calculate the broker fee amount that is going to be transferred to the `broker.account`.
        (brokerFeeAmount, depositAmount) = calculateAmountsFromFee(totalAmount, broker.fee);
    }

    /// @dev Descales the provided `amount` from 18 decimals fixed-point number to token's decimals number.
    function descaleAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        }

        unchecked {
            uint256 scaleFactor = 10 ** (18 - decimals);
            return amount / scaleFactor;
        }
    }

    /// @dev Scales the provided `amount` from token's decimals number to 18 decimals fixed-point number.
    function scaleAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        }

        unchecked {
            uint256 scaleFactor = 10 ** (18 - decimals);
            return amount * scaleFactor;
        }
    }
}
