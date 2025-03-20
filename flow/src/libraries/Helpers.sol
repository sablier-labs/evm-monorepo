// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title Helpers
/// @notice Library with helper functions in {SablierFlow} contract.
library Helpers {
    /// @notice Descales the provided `amount` from 18 decimals fixed-point number to token's decimals number.
    /// @dev If `decimals` exceeds 18, it will cause an underflow.
    function descaleAmount(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        }

        unchecked {
            uint256 scaleFactor = 10 ** (18 - decimals);
            return amount / scaleFactor;
        }
    }

    /// @notice Scales the provided `amount` from token's decimals number to 18 decimals fixed-point number.
    /// @dev If `decimals` exceeds 18, it will cause an underflow. If `amount` exceeds max value of `uint128`, the
    /// result may overflow `uint256`.
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
