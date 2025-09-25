// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { PRBMathUtils } from "@prb/math/test/utils/Utils.sol";
import { BaseUtils } from "@sablier/evm-utils/src/tests/BaseUtils.sol";
import { SafeCastLib } from "solady/src/utils/SafeCastLib.sol";
import { Constants } from "./Constants.sol";

abstract contract Utils is Constants, BaseUtils, PRBMathUtils {
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
        uint256 maxDepositAmount = getDescaledAmount({ amount: MAX_UINT128 - balance, decimals: decimals });
        depositAmount = boundUint128(amount, 1, uint128(maxDepositAmount - 1));
    }

    /// @dev Bound deposit amount within lower and upper bounds.
    function boundDepositAmount(
        uint128 amount,
        uint128 lowerBound18D,
        uint128 upperBound18D,
        uint8 decimals
    )
        internal
        pure
        returns (uint128 depositAmount)
    {
        uint256 lowerBound = getDescaledAmount({ amount: lowerBound18D, decimals: decimals });
        uint256 upperBound = getDescaledAmount({ amount: upperBound18D, decimals: decimals });
        depositAmount = boundUint128(amount, uint128(lowerBound), uint128(upperBound));
    }

    /// @dev Bounds the rate per second between a realistic range i.e. for USDC [$50/month $5000/month].
    function boundRatePerSecond(UD21x18 ratePerSecond) internal pure returns (UD21x18) {
        return boundRatePerSecond({
            ratePerSecond: ratePerSecond,
            minRatePerSecond: UD21x18.wrap(0.00002e18),
            maxRatePerSecond: UD21x18.wrap(0.002e18)
        });
    }

    /// @dev Bounds the rate per second between given min and max values.
    function boundRatePerSecond(
        UD21x18 ratePerSecond,
        UD21x18 minRatePerSecond,
        UD21x18 maxRatePerSecond
    )
        internal
        pure
        returns (UD21x18)
    {
        return bound(ratePerSecond, minRatePerSecond, maxRatePerSecond);
    }

    /// @dev Fuzz an address by excluding the zero address and the address provided.
    function fuzzAddrWithExclusion(address addr, address toExclude) internal view returns (address) {
        while (addr == address(0) || addr == toExclude) {
            addr = vm.randomAddress();
        }

        return addr;
    }

    /// @dev Calculates the default deposit amount using `TRANSFER_VALUE` and `decimals`.
    function getDefaultDepositAmount(uint8 decimals) internal pure returns (uint128 depositAmount) {
        return uint128(TRANSFER_VALUE * (10 ** decimals));
    }

    /// @dev Descales the amount to denote it in token's decimals.
    function getDescaledAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals >= 18) {
            return amount;
        }

        uint256 scaleFactor = (10 ** (18 - decimals));
        return amount / scaleFactor;
    }

    /// @dev Scales the amount to denote it in 18 decimals.
    function getScaledAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals >= 18) {
            return amount;
        }

        uint256 scaleFactor = (10 ** (18 - decimals));
        return amount * scaleFactor;
    }
}
