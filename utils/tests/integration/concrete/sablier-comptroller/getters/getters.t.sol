// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SablierComptroller_Concrete_Test } from "../SablierComptroller.t.sol";

contract Getters_Concrete_Test is SablierComptroller_Concrete_Test {
    /*//////////////////////////////////////////////////////////////////////////
                              GET-AIRDROPS-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetAirdropsMinFeeUSDGivenMinFeeNotSet() external view {
        assertEq(comptrollerZero.getAirdropsMinFeeUSD(), 0, "airdrop min fee USD not set");
    }

    function test_GetAirdropsMinFeeUSDGivenMinFeeSet() external view {
        assertEq(comptroller.getAirdropsMinFeeUSD(), AIRDROP_MIN_FEE_USD, "airdrop min fee USD set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                            GET-AIRDROPS-MIN-FEE-USD-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetAirdropsMinFeeUSDForGivenCustomFeeUSDNotSet() external view {
        assertEq(comptrollerZero.getAirdropsMinFeeUSDFor(users.campaignCreator), 0, "airdrop custom fee USD not set");
    }

    function test_GetAirdropsMinFeeUSDForGivenCustomFeeUSDSet() external view {
        assertEq(
            comptroller.getAirdropsMinFeeUSDFor(users.campaignCreator),
            AIRDROPS_CUSTOM_FEE_USD,
            "airdrop custom fee USD set"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                GET-FLOW-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetFlowMinFeeUSDGivenMinFeeNotSet() external view {
        assertEq(comptrollerZero.getFlowMinFeeUSD(), 0, "flow min fee USD not set");
    }

    function test_GetFlowMinFeeUSDGivenMinFeeSet() external view {
        assertEq(comptroller.getFlowMinFeeUSD(), FLOW_MIN_FEE_USD, "flow min fee USD set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                              GET-FLOW-MIN-FEE-USD-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetFlowMinFeeUSDForGivenCustomFeeUSDNotSet() external view {
        assertEq(comptrollerZero.getFlowMinFeeUSDFor(users.sender), 0, "flow custom fee USD not set");
    }

    function test_GetFlowMinFeeUSDForGivenCustomFeeUSDSet() external view {
        assertEq(comptroller.getFlowMinFeeUSDFor(users.sender), FLOW_CUSTOM_FEE_USD, "flow custom fee USD set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                               GET-LOCKUP-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetLockupMinFeeUSDGivenMinFeeNotSet() external view {
        assertEq(comptrollerZero.getLockupMinFeeUSD(), 0, "lockup min fee USD not set");
    }

    function test_GetLockupMinFeeUSDGivenMinFeeSet() external view {
        assertEq(comptroller.getLockupMinFeeUSD(), LOCKUP_MIN_FEE_USD, "lockup min fee USD set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                             GET-LOCKUP-MIN-FEE-USD-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetLockupMinFeeUSDForGivenCustomFeeUSDNotSet() external view {
        assertEq(comptrollerZero.getLockupMinFeeUSDFor(users.sender), 0, "lockup custom fee USD not set");
    }

    function test_GetLockupMinFeeUSDForGivenCustomFeeUSDSet() external view {
        assertEq(comptroller.getLockupMinFeeUSDFor(users.sender), LOCKUP_CUSTOM_FEE_USD, "lockup custom fee USD set");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       ORACLE
    //////////////////////////////////////////////////////////////////////////*/

    function test_OracleGivenOracleNotSet() external view {
        assertEq(comptrollerZero.oracle(), address(0), "oracle not set");
    }

    function test_OracleGivenOracleSet() external view {
        assertEq(comptroller.oracle(), address(oracle), "oracle set");
    }
}
