// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { stdStorage, StdStorage } from "forge-std/src/StdStorage.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import {
    ChainlinkOracleFutureDatedPrice,
    ChainlinkOracleNegativePrice,
    ChainlinkOracleOutdatedPrice,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "tests/Base.t.sol";

contract ConvertUSDFeeToWei_Comptroller_Concrete_Test is Base_Test {
    using stdStorage for StdStorage;

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

        // Use `vm.store` since `setOracle` function reverts if call to `latestRoundData` fails.
        uint256 oracleSlot = stdstore.target(address(comptroller)).sig(ISablierComptroller.oracle.selector).find();
        vm.store(address(comptroller), bytes32(oracleSlot), bytes32(uint256(uint160(revertOracle))));

        // Check: the oracle is modified.
        assertEq(comptroller.oracle(), revertOracle, "oracle not modified");

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "oracle call failed");
    }

    function test_WhenOraclePriceNegative(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenLatestRoundCallNotFail
    {
        comptroller.setOracle(address(new ChainlinkOracleNegativePrice()));

        // It should return zero.
        assertEq(comptroller.convertUSDFeeToWei(feeUSD), 0, "negative price");
    }

    function test_WhenOracleUpdatedTimeInFuture(uint128 feeUSD)
        external
        givenOracleNotZero
        whenFeeUSDNotZero
        whenLatestRoundCallNotFail
        whenOraclePriceNotNegative
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
        whenOraclePriceNotNegative
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
        whenOraclePriceNotNegative
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
        whenOraclePriceNotNegative
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
        whenOraclePriceNotNegative
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
        whenOraclePriceNotNegative
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
        whenOraclePriceNotNegative
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
