// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Broker } from "./../types/DataTypes.sol";
import { Errors } from "./Errors.sol";

/// @title Helpers
/// @notice Library with helper functions in {SablierFlow} contract.
library Helpers {
    using SafeCast for uint256;

    /// @dev Checks the `Broker` parameter, and then calculates the broker fee amount and the deposit amount from the
    /// total amount.
    function checkAndCalculateBrokerFee(
        uint128 totalAmount,
        Broker memory broker,
        UD60x18 maxBrokerFee
    )
        internal
        pure
        returns (uint128 brokerFeeAmount, uint128 depositAmount)
    {
        // Check: the broker's fee is not greater than `MAX_BROKER_FEE`.
        if (broker.fee.gt(maxBrokerFee)) {
            revert Errors.SablierFlow_BrokerFeeTooHigh(broker.fee, maxBrokerFee);
        }

        // Check: the broker recipient is not the zero address.
        if (broker.account == address(0)) {
            revert Errors.SablierFlow_BrokerAddressZero();
        }

        // Calculate the broker fee amount that is going to be transferred to the `broker.account`.
        // The cast to uint128 is safe because the maximum fee is hard coded.
        brokerFeeAmount = ud(totalAmount).mul(broker.fee).intoUint256().toUint128();

        // Calculate the deposit amount to the Flow contract.
        depositAmount = totalAmount - brokerFeeAmount;
    }

    /// @notice Denormalizes the provided amount to be denoted in the token's decimals.
    /// @dev The following logic is used to denormalize the amount:
    /// - If the token has exactly 18 decimals, the amount is returned as is.
    /// - If the token has fewer than 18 decimals, the amount is divided by $10^(18 - tokenDecimals)$.
    function denormalizeAmount(uint128 normalizedAmount, uint8 tokenDecimals) internal pure returns (uint128 amount) {
        // Return the original amount if token's decimals is 18.
        if (tokenDecimals == 18) {
            return normalizedAmount;
        }

        // Safe to use unchecked because we use {SafeCast}.
        unchecked {
            uint8 factor = 18 - tokenDecimals;
            amount = (normalizedAmount / (10 ** factor)).toUint128();
        }
    }

    /// @notice Normalizes the provided amount to be denoted in 18 decimals.
    /// @dev The following logic is used to normalize the amount:
    /// - If the token has exactly 18 decimals, the amount is returned as is.
    /// - If the token has fewer than 18 decimals, the amount is multiplied by $10^(18 - tokenDecimals)$.
    function normalizeAmount(uint128 amount, uint8 tokenDecimals) internal pure returns (uint128 normalizedAmount) {
        // Return the original amount if token's decimals is 18.
        if (tokenDecimals == 18) {
            return amount;
        }

        // Safe to use unchecked because we use {SafeCast}.
        unchecked {
            uint8 factor = 18 - tokenDecimals;
            normalizedAmount = (amount * (10 ** factor)).toUint128();
        }
    }
}
