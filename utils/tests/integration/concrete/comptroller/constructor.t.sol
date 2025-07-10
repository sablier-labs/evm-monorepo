// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Base_Test } from "../../../Base.t.sol";

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

contract Comptroller_Constructor_Concrete_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_Constructor() public view {
        // Constants and variables.
        assertEq(comptroller.admin(), admin, "admin");
        assertEq(comptroller.MAX_FEE_USD(), MAX_FEE_USD, "max fee USD");
        assertEq(comptroller.oracle(), address(oracle), "oracle");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  GET-MIN-FEE-USD
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetMinFeeUSD() public view {
        assertEq(
            comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Airdrops),
            AIRDROP_MIN_FEE_USD,
            "get min fee USD Airdrops"
        );
        assertEq(comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Flow), FLOW_MIN_FEE_USD, "get min fee USD Flow");
        assertEq(
            comptroller.getMinFeeUSD(ISablierComptroller.Protocol.Lockup), LOCKUP_MIN_FEE_USD, "get min fee USD Lockup"
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                GET-MIN-FEE-USD-FOR
    //////////////////////////////////////////////////////////////////////////*/

    function test_GetMinFeeUSDFor(address user) public view {
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Airdrops, user),
            AIRDROP_MIN_FEE_USD,
            "get min fee USD Airdrops for user"
        );
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Flow, user),
            FLOW_MIN_FEE_USD,
            "get min fee USD Flow for user"
        );
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Lockup, user),
            LOCKUP_MIN_FEE_USD,
            "get min fee USD Lockup for user"
        );
        assertEq(
            comptroller.getMinFeeUSDFor(ISablierComptroller.Protocol.Staking, user),
            STAKING_MIN_FEE_USD,
            "get min fee USD Staking for user"
        );
    }
}
