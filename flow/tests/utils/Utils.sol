// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";

import { SafeCastLib } from "solady/src/utils/SafeCastLib.sol";
import { Constants } from "./Constants.sol";

abstract contract Utils is Constants, PRBMathUtils {
    using SafeCastLib for uint256;

    /// @dev Bound deposit amount to avoid overflow.
    function boundDepositAmount(
        uint128 amount,
        uint128 balance,
        uint8 decimals
    )
        internal
        pure
        returns (uint128 depositAmount)
    {
        uint128 maxDepositAmount = (type(uint128).max - balance);
        if (decimals < 18) {
            maxDepositAmount = maxDepositAmount / uint128(10 ** (18 - decimals));
        }

        depositAmount = uint128(_bound(amount, 1, maxDepositAmount - 1));
    }

    /// @dev Bounds the rate per second between a realistic range i.e. for USDC [$50/month $5000/month].
    function boundRatePerSecond(UD21x18 ratePerSecond) internal pure returns (UD21x18) {
        return bound(ratePerSecond, 0.00002e18, 0.002e18);
    }

    /// @dev Calculates the default deposit amount using `TRANSFER_VALUE` and `decimals`.
    function getDefaultDepositAmount(uint8 decimals) internal pure returns (uint128 depositAmount) {
        return TRANSFER_VALUE * (10 ** decimals).toUint128();
    }

    /// @dev Descales the amount to denote it in token's decimals.
    function getDescaledAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        }

        uint256 scaleFactor = (10 ** (18 - decimals));
        return amount / scaleFactor;
    }

    /// @dev Scales the amount to denote it in 18 decimals.
    function getScaledAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        }

        uint256 scaleFactor = (10 ** (18 - decimals));
        return amount * scaleFactor;
    }
}
