// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import {
    ChainlinkOracleOutdated,
    ChainlinkOracleFuture,
    ChainlinkOracleWith18Decimals,
    ChainlinkOracleWith6Decimals,
    ChainlinkOracleZeroPrice
} from "src/mocks/ChainlinkMocks.sol";

import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract Calculations_Concrete_Test is SablierComptroller_Concrete_Test {
    /*//////////////////////////////////////////////////////////////////////////
                           CALCULATE-AIRDROPS-MIN-FEE-WEI
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateAirdropsMinFeeWeiGivenMinFeeNotSet() external view {
        assertEq(comptrollerZero.calculateAirdropsMinFeeWei(), 0, "min fee wei airdrops not set");
    }

    function test_CalculateAirdropsMinFeeWeiGivenMinFeeSet() external view {
        assertEq(comptroller.calculateAirdropsMinFeeWei(), AIRDROP_MIN_FEE_WEI, "min fee wei airdrops set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                         CALCULATE-AIRDROPS-MIN-FEE-WEI-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateAirdropsMinFeeWeiForGivenCustomFeeNotSet() external view {
        assertEq(
            comptrollerZero.calculateAirdropsMinFeeWeiFor(users.campaignCreator),
            0,
            "min fee wei airdrops custom not set"
        );
    }

    function test_CalculateAirdropsMinFeeWeiForGivenCustomFeeSet() external view {
        assertEq(
            comptroller.calculateAirdropsMinFeeWeiFor(users.campaignCreator),
            AIRDROPS_CUSTOM_FEE_WEI,
            "min fee wei airdrops custom set"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                             CALCULATE-FLOW-MIN-FEE-WEI
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateFlowMinFeeWeiGivenMinFeeNotSet() external view {
        assertEq(comptrollerZero.calculateFlowMinFeeWei(), 0, "min fee wei flow not set");
    }

    function test_CalculateFlowMinFeeWeiGivenMinFeeSet() external view {
        assertEq(comptroller.calculateFlowMinFeeWei(), FLOW_MIN_FEE_WEI, "min fee wei flow set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                           CALCULATE-FLOW-MIN-FEE-WEI-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateFlowMinFeeWeiForGivenCustomFeeNotSet() external view {
        assertEq(comptrollerZero.calculateFlowMinFeeWeiFor(users.sender), 0, "min fee wei flow custom not set");
    }

    function test_CalculateFlowMinFeeWeiForGivenCustomFeeSet() external view {
        assertEq(
            comptroller.calculateFlowMinFeeWeiFor(users.sender), FLOW_CUSTOM_FEE_WEI, "min fee wei flow custom set"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CALCULATE-LOCKUP-MIN-FEE-WEI
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateLockupMinFeeWeiGivenMinFeeNotSet() external view {
        assertEq(comptrollerZero.calculateLockupMinFeeWei(), 0, "min fee wei lockup not set");
    }

    function test_CalculateLockupMinFeeWeiGivenMinFeeSet() external view {
        assertEq(comptroller.calculateLockupMinFeeWei(), LOCKUP_MIN_FEE_WEI, "min fee wei lockup set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                          CALCULATE-LOCKUP-MIN-FEE-WEI-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateLockupMinFeeWeiForGivenCustomFeeNotSet() external view {
        assertEq(comptrollerZero.calculateLockupMinFeeWeiFor(users.sender), 0, "min fee wei lockup custom not set");
    }

    function test_CalculateLockupMinFeeWeiForGivenCustomFeeSet() external view {
        assertEq(
            comptroller.calculateLockupMinFeeWeiFor(users.sender),
            LOCKUP_CUSTOM_FEE_WEI,
            "min fee wei lockup custom set"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                               CALCULATE-MIN-FEE-WEI
    //////////////////////////////////////////////////////////////////////////*/

    function test_CalculateMinFeeWeiGivenOracleZero() external {
        comptroller.setOracle(address(0));

        // It should return zero.
        assertEq(comptrollerZero.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), 0, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenMinFeeUSDZero() external view givenOracleNotZero {
        // It should return zero.
        assertEq(comptroller.calculateMinFeeWei(0), 0, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenOracleUpdatedTimeInFuture() external givenOracleNotZero whenMinFeeUSDNotZero {
        comptroller.setOracle(address(new ChainlinkOracleFuture()));

        // It should return zero.
        assertEq(comptroller.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), 0, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenOraclePriceOutdated()
        external
        givenOracleNotZero
        whenMinFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
    {
        comptroller.setOracle(address(new ChainlinkOracleOutdated()));

        // It should return zero.
        assertEq(comptroller.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), 0, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenOraclePriceZero()
        external
        givenOracleNotZero
        whenMinFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
    {
        comptroller.setOracle(address(new ChainlinkOracleZeroPrice()));

        // It should return zero.
        assertEq(comptroller.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), 0, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenOraclePriceHasEightDecimals()
        external
        view
        givenOracleNotZero
        whenMinFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        // It should calculate the min fee in wei.
        assertEq(comptroller.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), AIRDROP_MIN_FEE_WEI, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenOraclePriceHasMoreThanEightDecimals()
        external
        givenOracleNotZero
        whenMinFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        comptroller.setOracle(address(new ChainlinkOracleWith18Decimals()));

        // It should calculate the min fee in wei.
        assertEq(comptroller.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), AIRDROP_MIN_FEE_WEI, "min fee wei");
    }

    function test_CalculateMinFeeWeiWhenOraclePriceHasLessThanEightDecimals()
        external
        givenOracleNotZero
        whenMinFeeUSDNotZero
        whenOracleUpdatedTimeNotInFuture
        whenOraclePriceNotOutdated
        whenOraclePriceNotZero
    {
        comptroller.setOracle(address(new ChainlinkOracleWith6Decimals()));

        // It should calculate the min fee in wei.
        assertEq(comptroller.calculateMinFeeWei(AIRDROP_MIN_FEE_USD), AIRDROP_MIN_FEE_WEI, "min fee wei");
    }
}
