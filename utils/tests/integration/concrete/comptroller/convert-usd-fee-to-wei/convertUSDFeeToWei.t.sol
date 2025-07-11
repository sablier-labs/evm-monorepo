// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import {
    ChainlinkOracleFutureDatedPrice,
    ChainlinkOracleOutdatedPrice,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice,
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

    function test_WhenLatestRoundCallFails(uint128 feeUSD) external givenOracleNotZero whenFeeUSDNotZero {
        address revertOracle = address(new ChainlinkOracleWithRevertingPrice());

        // Try different slots until we find the right one (it should be at 2, but we use this approach in case it
        // going to change)
        for (uint256 slot = 0; slot < 10; ++slot) {
            bytes32 currentValue = vm.load(address(comptroller), bytes32(slot));
            if (address(uint160(uint256(currentValue))) == address(oracle)) {
                // Use `vm.store` instead of `setOracle` as this function checks if `latestRoundData` call fails.
                vm.store(address(comptroller), bytes32(slot), bytes32(uint256(uint160(revertOracle))));
                break;
            }
        }

        assertEq(comptroller.oracle(), revertOracle, "oracle not modified");

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "oracle call failed");
    }

    function test_WhenOracleUpdatedTimeInFuture(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenLatestRoundCallNotFail
    {
        comptroller.setOracle(address(new ChainlinkOracleFutureDatedPrice()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "future oracle");
    }

    function test_WhenOraclePriceOutdated(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenLatestRoundCallNotFail
        whenOracleUpdatedTimeNotInFuture
    {
        comptroller.setOracle(address(new ChainlinkOracleOutdatedPrice()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "outdated oracle");
    }

    function test_WhenDecimalsCallFails(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenLatestRoundCallNotFail
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
    {
        comptroller.setOracle(address(new ChainlinkOracleWithRevertingDecimals()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "decimals call failed");
    }

    function test_WhenOraclePriceZero(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenLatestRoundCallNotFail
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenDecimalsCallNotFail
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
        whenLatestRoundCallNotFail
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenDecimalsCallNotFail
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
        whenLatestRoundCallNotFail
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenDecimalsCallNotFail
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
        whenLatestRoundCallNotFail
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenDecimalsCallNotFail
        whenOraclePriceNotZero
    {
        comptroller.setOracle(address(new ChainlinkOracleWith6Decimals()));

        // It should convert the fee to wei.
        uint256 actualFeeInWei = comptroller.convertUSDFeeToWei(feeUSD);
        uint256 expectedFeeInWei = convertUSDToWei(feeUSD);
        assertEq(actualFeeInWei, expectedFeeInWei, "less than eight decimals");
    }
}
