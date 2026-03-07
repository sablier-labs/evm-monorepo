// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { Errors } from "./Errors.sol";

/// @title SafeOracle
/// @notice Library with helper functions for fetching and validating oracle prices.
library SafeOracle {
    using SafeCast for uint256;

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Fetches the latest price from the oracle. Returns 0 if any of the following conditions are met:
    /// - Oracle address is zero.
    /// - Call to `latestRoundData()` fails.
    /// - Call to `decimals()` fails.
    /// - The `decimals()` call returns 0 or more than 36 decimals.
    /// - The price is not positive.
    /// - The price exceeds `uint128` max.
    /// - The `updatedAt` timestamp is in the future.
    /// - `normalize` is true, and the normalized price exceeds `uint128` max.
    ///
    /// @param oracle The Chainlink oracle to query.
    /// @param normalize If true, normalizes the price to 8 decimals. If false, returns the price in the oracle's
    /// native decimals.
    function safeOraclePrice(
        AggregatorV3Interface oracle,
        bool normalize
    )
        internal
        view
        returns (uint128 price, uint8 decimals, uint256 updatedAt)
    {
        // If the oracle is not set, return 0 for both price and updated timestamp.
        if (address(oracle) == address(0)) {
            return (0, 0, 0);
        }

        uint8 oracleDecimals;

        try oracle.decimals() returns (uint8 _oracleDecimals) {
            // If decimals exceed 36 or is zero, return 0 to avoid overflow/underflow in normalization.
            if (_oracleDecimals > 36 || _oracleDecimals == 0) {
                return (0, 0, 0);
            }

            oracleDecimals = _oracleDecimals;
        } catch {
            // If the decimals call fails, return 0.
            return (0, 0, 0);
        }

        // Interactions: query the oracle price and the time at which it was updated.
        try oracle.latestRoundData() returns (uint80, int256 _price, uint256, uint256 _updatedAt, uint80) {
            // If the price is not greater than 0, return 0 for price.
            if (_price <= 0) {
                return (0, oracleDecimals, _updatedAt);
            }

            // Due to reorgs and latency issues, the oracle can have an `updatedAt` timestamp in the future.
            if (block.timestamp < _updatedAt) {
                return (0, oracleDecimals, _updatedAt);
            }

            uint256 oraclePrice = uint256(_price);

            // If the initial price is greater than max `uint128`, return 0 for price.
            if (oraclePrice > type(uint128).max) {
                return (0, oracleDecimals, _updatedAt);
            }

            uint256 normalizedPrice = oraclePrice;

            // Normalize to 8 decimals only if requested.
            if (normalize && oracleDecimals != 8) {
                normalizedPrice = _normalizePrice(oraclePrice, oracleDecimals);

                // If the normalized price is greater than max `uint128`, return 0 for price.
                if (normalizedPrice > type(uint128).max) {
                    return (0, oracleDecimals, _updatedAt);
                }
            }

            // It's safe to cast as we checked that the price does not exceed `uint128` above.
            price = uint128(normalizedPrice);
            decimals = normalize ? 8 : oracleDecimals;
            updatedAt = _updatedAt;
        } catch {
            // If the oracle call fails, return 0 for both price and updated timestamp.
            return (0, 0, 0);
        }
    }

    /// @dev Validates the oracle address and reverts if any of the following conditions are met:
    /// - Oracle address is zero.
    /// - Oracle does not implement the `decimals()` function, returns 0, or returns more than 36 decimals.
    /// - Oracle does not return a positive price when `latestRoundData()` is called.
    ///
    /// Returns the latest price normalized to 8 decimals.
    function validateOracle(AggregatorV3Interface oracle) internal view returns (uint128 price) {
        // Check: oracle address is not zero. This is needed because calling a function on address(0) succeeds but
        // returns empty data, which causes the ABI decoder to fail.
        if (address(oracle) == address(0)) {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }

        // Check: oracle implements the `decimals()` function and returns a valid value.
        uint8 oracleDecimals;
        try oracle.decimals() returns (uint8 _decimals) {
            // Check: decimals is not zero.
            if (_decimals == 0) {
                revert Errors.SafeOracle_DecimalsZero(address(oracle));
            }

            // Check: decimals is not too high to avoid overflow in normalization.
            if (_decimals > 36) {
                revert Errors.SafeOracle_DecimalsTooHigh(address(oracle), _decimals);
            }

            oracleDecimals = _decimals;
        } catch {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }

        // Check: oracle returns a positive price when `latestRoundData()` is called.
        uint256 normalizedPrice;
        try oracle.latestRoundData() returns (uint80, int256 _price, uint256, uint256, uint80) {
            // Because users may not always use Chainlink oracles, we do not check for the staleness of the price.
            if (_price <= 0) {
                revert Errors.SafeOracle_NotPositivePrice(address(oracle));
            }
            normalizedPrice = _normalizePrice(uint256(_price), oracleDecimals);
        } catch {
            revert Errors.SafeOracle_MissesInterface(address(oracle));
        }

        // Use `SafeCast` to cast the normalized price to `uint128`.
        price = normalizedPrice.toUint128();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            PRIVATE READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Normalizes the price from oracle decimals to 8 decimals.
    function _normalizePrice(uint256 price, uint8 oracleDecimals) private pure returns (uint256) {
        if (oracleDecimals > 8) {
            return price / (10 ** (oracleDecimals - 8));
        }

        if (oracleDecimals < 8) {
            return price * (10 ** (8 - oracleDecimals));
        }

        return price;
    }
}
