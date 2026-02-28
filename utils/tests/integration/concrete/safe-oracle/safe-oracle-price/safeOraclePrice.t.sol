// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import {
    ChainlinkOracleFutureDatedPrice,
    ChainlinkOracleMock,
    ChainlinkOracleNegativePrice,
    ChainlinkOracleOverflowPrice,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract SafeOraclePrice_SafeOracle_Concrete_Test is Base_Test {
    function test_WhenOracleAddressZero() external view {
        // It should return zero for both price and updatedAt.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(0)));
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenLatestRoundCallFails() external whenOracleAddressNotZero {
        ChainlinkOracleWithRevertingPrice oracle = new ChainlinkOracleWithRevertingPrice();

        // It should return zero for both price and updatedAt.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "price");
        assertEq(updatedAt, 0, "updatedAt");
    }

    function test_WhenOraclePriceNegative() external whenOracleAddressNotZero whenLatestRoundCallNotFail {
        ChainlinkOracleNegativePrice oracle = new ChainlinkOracleNegativePrice();

        // It should return zero for price.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOraclePriceZero() external whenOracleAddressNotZero whenLatestRoundCallNotFail {
        ChainlinkOracleZeroPrice oracle = new ChainlinkOracleZeroPrice();

        // It should return zero for price.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOraclePriceExceedsUint128Max()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePricePositive
    {
        ChainlinkOracleOverflowPrice oracle = new ChainlinkOracleOverflowPrice();

        // It should return zero for price.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }

    function test_WhenOracleUpdatedTimeInFuture()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOraclePriceNotExceedUint128Max
    {
        ChainlinkOracleFutureDatedPrice oracle = new ChainlinkOracleFutureDatedPrice();

        // It should return zero for price.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 0, "price");
        assertEq(updatedAt, getBlockTimestamp() + 1, "updatedAt");
    }

    function test_WhenOracleUpdatedTimeNotInFuture()
        external
        whenOracleAddressNotZero
        whenLatestRoundCallNotFail
        whenOraclePricePositive
        whenOraclePriceNotExceedUint128Max
        whenOracleUpdatedTimeNotInFuture
    {
        ChainlinkOracleMock oracle = new ChainlinkOracleMock();

        // It should return the latest price and updatedAt.
        (uint128 price, uint256 updatedAt) = safeOracleMock.safeOraclePrice(AggregatorV3Interface(address(oracle)));
        assertEq(price, 3000e8, "price");
        assertEq(updatedAt, getBlockTimestamp(), "updatedAt");
    }
}
