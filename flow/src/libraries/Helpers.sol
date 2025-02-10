// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ud, UD60x18 } from "@prb/math/src/UD60x18.sol";

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
