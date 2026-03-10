// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {
    ChainlinkOracleFutureDatedPrice,
    ChainlinkOracleMock,
    ChainlinkOracleNegativePrice,
    ChainlinkOracleNormalizedOverflowPrice,
    ChainlinkOracleOverflowPrice,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith37Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleWithZeroDecimals,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SafeOraclePrice_SafeOracle_Concrete_Test is Base_Test {
    function test_WhenOracleAddressZero() external view {
        // It should return zero for both price and updatedAt.
        (uint128 price,, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(0)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenDecimalsCallFails() external whenOracleAddressNotZero {
        ChainlinkOracleWithRevertingDecimals oracle = new ChainlinkOracleWithRevertingDecimals();

        // It should return zero for both price and updatedAt.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenOracleDecimalsZero() external whenOracleAddressNotZero whenDecimalsCallNotFail {
        ChainlinkOracleWithZeroDecimals oracle = new ChainlinkOracleWithZeroDecimals();

        // It should return zero for both price and updatedAt.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenOracleDecimalsTooHigh()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
    {
        ChainlinkOracleWith37Decimals oracle = new ChainlinkOracleWith37Decimals();

        // It should return zero for both price and updatedAt.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenLatestRoundCallFails()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
    {
        ChainlinkOracleWithRevertingPrice oracle = new ChainlinkOracleWithRevertingPrice();

        // It should return zero for both price and updatedAt.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenOraclePriceNegative()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
    {
        ChainlinkOracleNegativePrice oracle = new ChainlinkOracleNegativePrice();

        // It should return zero for price.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOraclePriceZero()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
    {
        ChainlinkOracleZeroPrice oracle = new ChainlinkOracleZeroPrice();

        // It should return zero for price.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleUpdatedTimeInFuture()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
    {
        ChainlinkOracleFutureDatedPrice oracle = new ChainlinkOracleFutureDatedPrice();

        // It should return zero for price.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp() + 1, "updatedAt");
    }

    function test_WhenOraclePriceExceedsUint128Max()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
    {
        ChainlinkOracleOverflowPrice oracle = new ChainlinkOracleOverflowPrice();

        // It should return zero for price.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenNormalizedPriceExceedsUint128Max()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNormalized
    {
        ChainlinkOracleNormalizedOverflowPrice oracle = new ChainlinkOracleNormalizedOverflowPrice();

        // It should return zero for price.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleReturnsEightDecimals()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNormalized
        whenNormalizedPriceNotExceedUint128Max
    {
        ChainlinkOracleMock oracleMock = new ChainlinkOracleMock();

        // It should return the price as-is.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracleMock)), true);
        assertEq(price, 3000e8, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleReturnsMoreThanEightDecimals()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNormalized
        whenNormalizedPriceNotExceedUint128Max
    {
        ChainlinkOracleWith18Decimals oracleMock = new ChainlinkOracleWith18Decimals();

        // It should return the price normalized to eight decimals.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracleMock)), true);
        assertEq(price, 3000e8, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleReturnsLessThanEightDecimals()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNormalized
        whenNormalizedPriceNotExceedUint128Max
    {
        ChainlinkOracleWith6Decimals oracle = new ChainlinkOracleWith6Decimals();

        // It should return the price scaled up to eight decimals.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), true);
        assertEq(price, 3000e8, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleHasEightDecimals()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNotNormalized
    {
        ChainlinkOracleMock oracleMock = new ChainlinkOracleMock();

        // It should return the price as-is.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracleMock)), false);
        assertEq(price, 3000e8, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleHasMoreThanEightDecimals()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNotNormalized
    {
        ChainlinkOracleWith18Decimals oracleMock = new ChainlinkOracleWith18Decimals();

        // It should return the price in native decimals.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracleMock)), false);
        assertEq(price, 3000e18, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleHasLessThanEightDecimals()
        external
        whenOracleAddressNotZero
        whenDecimalsCallNotFail
        whenOracleDecimalsNotZero
        whenOracleDecimalsNotTooHigh
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotExceedUint128Max
        whenPriceNotNormalized
    {
        ChainlinkOracleWith6Decimals oracle = new ChainlinkOracleWith6Decimals();

        // It should return the price in native decimals.
        (uint128 price,, uint256 updatedAt) =
            safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)), false);
        assertEq(price, 3000e6, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }
}
