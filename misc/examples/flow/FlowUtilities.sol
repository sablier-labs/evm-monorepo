// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ud21x18, UD21x18 } from "@prb/math/src/UD21x18.sol";

/// @dev A utility library to calculate rate per second and streamed amount based on a given time frame.
library FlowUtilities {
    /// @notice This function calculates the rate per second based on a given amount of tokens and a specified duration.
    /// @dev The rate per second is a 18-decimal fixed-point number and it is calculated as `amount / duration`.
    /// @param token The address of the token.
    /// @param amount The amount of tokens, denoted in token's decimals.
    /// @param duration The duration in seconds user wishes to stream.
    /// @return ratePerSecond The rate per second as a 18-decimal fixed-point number.
    function ratePerSecondWithDuration(
        address token,
        uint128 amount,
        uint40 duration
    )
        internal
        view
        returns (UD21x18 ratePerSecond)
    {
        // Get the decimals of the token.
        uint8 decimals = IERC20Metadata(token).decimals();

        // If the token has 18 decimals, we can simply divide the amount by the duration as it returns a 18 decimal
        // fixed-point number.
        if (decimals == 18) {
            return ud21x18(amount / duration);
        }

        // Calculate the scale factor from the token's decimals.
        uint128 scaleFactor = uint128(10 ** (18 - decimals));

        // Multiply the amount by the scale factor and divide by the duration.
        ratePerSecond = ud21x18((scaleFactor * amount) / duration);
    }

    /// @notice This function calculates the rate per second based on a given amount of tokens and a specified range.
    /// @dev The rate per second is a 18-decimal fixed-point number and it is calculated as `amount / (end - start)`.
    /// @param token The address of the token.
    /// @param amount The amount of tokens, denoted in token's decimals.
    /// @param start The start timestamp.
    /// @param end The end timestamp.
    /// @return ratePerSecond The rate per second as a 18-decimal fixed-point number.
    function ratePerSecondForTimestamps(
        address token,
        uint128 amount,
        uint40 start,
        uint40 end
    )
        internal
        view
        returns (UD21x18 ratePerSecond)
    {
        // Calculate the duration.
        uint40 duration = end - start;

        // Get the decimals of the token.
        uint8 decimals = IERC20Metadata(token).decimals();

        if (decimals == 18) {
            return ud21x18(amount / duration);
        }

        // Calculate the scale factor from the token's decimals.
        uint128 scaleFactor = uint128(10 ** (18 - decimals));

        // Multiply the amount by the scale factor and divide by the duration.
        ratePerSecond = ud21x18((scaleFactor * amount) / duration);
    }

    /// @notice This function calculates the amount streamed over a week for a given rate per second.
    /// @param ratePerSecond The rate per second as a 18-decimal fixed-point number.
    /// @return amountPerWeek The amount streamed over a week.
    function calculateAmountStreamedPerWeek(UD21x18 ratePerSecond) internal pure returns (uint128 amountPerWeek) {
        amountPerWeek = ratePerSecond.unwrap() * 1 weeks;
    }

    /// @notice This function calculates the amount streamed over a month for a given rate per second.
    /// @dev For simplicity, we have assumed that there are 30 days in a month.
    /// @param ratePerSecond The rate per second as a 18-decimal fixed-point number.
    /// @return amountPerMonth The amount streamed over a month.
    function calculateAmountStreamedPerMonth(UD21x18 ratePerSecond) internal pure returns (uint128 amountPerMonth) {
        amountPerMonth = ratePerSecond.unwrap() * 30 days;
    }

    /// @notice This function calculates the amount streamed over a year for a given rate per second.
    /// @dev For simplicity, we have assumed that there are 365 days in a year.
    /// @param ratePerSecond The rate per second as a fixed-point number.
    /// @return amountPerYear The amount streamed over a year.
    function calculateAmountStreamedPerYear(UD21x18 ratePerSecond) internal pure returns (uint128 amountPerYear) {
        amountPerYear = ratePerSecond.unwrap() * 365 days;
    }
}
