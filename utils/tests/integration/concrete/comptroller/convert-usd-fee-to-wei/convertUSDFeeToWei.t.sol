// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import {
    ChainlinkOracleOutdated,
    ChainlinkOracleFuture,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "tests/Base.t.sol";

contract ConvertUSDFeeToWei_Comptroller_Concrete_Test is Base_Test {
    function test_GivenOracleZero(uint128 feeUSD) external {
        comptroller.setOracle(address(0));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "zero oracle");
    }

    function test_WhenFeeUSDZero() external view givenOracleNotZero {
        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(0), 0, "zero fee");
    }

    function test_WhenOracleUpdatedTimeInFuture(uint128 feeUSD) external givenOracleNotZero whenFeeUSDNotZero {
        comptroller.setOracle(address(new ChainlinkOracleFuture()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "future oracle");
    }

    function test_WhenOraclePriceOutdated(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
    {
        comptroller.setOracle(address(new ChainlinkOracleOutdated()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "outdated oracle");
    }

    function test_WhenOraclePriceZero(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
    {
        comptroller.setOracle(address(new ChainlinkOracleZeroPrice()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "zero price");
    }

    function test_WhenOracleReturnsEightDecimals(uint128 feeUSD)
        external
        view
        givenOracleNotZero
        whenFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "eight decimals");
    }

    function test_WhenOracleReturnsMoreThanEightDecimals(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        comptroller.setOracle(address(new ChainlinkOracleWith18Decimals()));

        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "more than eight decimals");
    }

    function test_WhenOracleReturnsLessThanEightDecimals(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        comptroller.setOracle(address(new ChainlinkOracleWith6Decimals()));

        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "less than eight decimals");
    }
}
