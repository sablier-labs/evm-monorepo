// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Errors } from "src/libraries/Errors.sol";
import {
    ChainlinkOracleMock,
    ChainlinkOracleNegativePrice,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWithRevertingDecimals,
    ChainlinkOracleWithRevertingPrice,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract ValidateOracle_SafeOracle_Concrete_Test is Base_Test {
    function test_RevertWhen_OracleAddressZero() external {
        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_MissesInterface.selector, address(0)));
        safeOracleMock.validateOracle(AggregatorV3Interface(address(0)));
    }

    function test_RevertWhen_OracleMissesDecimals() external whenOracleAddressNotZero {
        ChainlinkOracleWithRevertingDecimals oracle = new ChainlinkOracleWithRevertingDecimals();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_MissesInterface.selector, address(oracle)));
        safeOracleMock.validateOracle(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OracleDecimalsNot8() external whenOracleAddressNotZero whenOracleNotMissDecimals {
        ChainlinkOracleWith18Decimals oracle = new ChainlinkOracleWith18Decimals();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_DecimalsNotEight.selector, address(oracle), 18));
        safeOracleMock.validateOracle(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OracleMissesLatestRoundData()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
    {
        ChainlinkOracleWithRevertingPrice oracle = new ChainlinkOracleWithRevertingPrice();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_MissesInterface.selector, address(oracle)));
        safeOracleMock.validateOracle(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OraclePriceNegative()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
    {
        ChainlinkOracleNegativePrice oracle = new ChainlinkOracleNegativePrice();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_NotPositivePrice.selector, address(oracle)));
        safeOracleMock.validateOracle(AggregatorV3Interface(address(oracle)));
    }

    function test_RevertWhen_OraclePriceZero()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
    {
        ChainlinkOracleZeroPrice oracle = new ChainlinkOracleZeroPrice();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SafeOracle_NotPositivePrice.selector, address(oracle)));
        safeOracleMock.validateOracle(AggregatorV3Interface(address(oracle)));
    }

    function test_WhenOraclePricePositive()
        external
        whenOracleAddressNotZero
        whenOracleNotMissDecimals
        whenOracleDecimals8
        whenOracleNotMissLatestRoundData
    {
        ChainlinkOracleMock oracle = new ChainlinkOracleMock();

        // It should return the latest price.
        uint128 latestPrice = safeOracleMock.validateOracle(AggregatorV3Interface(address(oracle)));
        assertEq(latestPrice, 3000e8, "latestPrice");
    }
}
