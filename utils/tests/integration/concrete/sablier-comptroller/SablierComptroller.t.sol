// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SablierComptroller } from "src/SablierComptroller.sol";

import { Base_Test } from "../../../Base.t.sol";

abstract contract SablierComptroller_Concrete_Test is Base_Test {
    // The comptroller with zero values.
    SablierComptroller internal comptrollerZero;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the Sablier Comptroller with zero values.
        comptrollerZero = new SablierComptroller(admin, 0, 0, 0, address(0));

        // Set the custom fees.
        comptroller.setAirdropsCustomFeeUSD(users.campaignCreator, AIRDROPS_CUSTOM_FEE_USD);
        comptroller.setFlowCustomFeeUSD(users.sender, FLOW_CUSTOM_FEE_USD);
        comptroller.setLockupCustomFeeUSD(users.sender, LOCKUP_CUSTOM_FEE_USD);
    }

    function test_Constructor() public view {
        // Assert the state variables.
        assertEq(comptroller.admin(), admin, "admin");
        assertEq(comptroller.getAirdropsMinFeeUSD(), AIRDROP_MIN_FEE_USD, "airdrop min fee");
        assertEq(comptroller.getFlowMinFeeUSD(), FLOW_MIN_FEE_USD, "flow min fee");
        assertEq(comptroller.getLockupMinFeeUSD(), LOCKUP_MIN_FEE_USD, "lockup min fee");
        assertEq(comptroller.MAX_FEE_USD(), 100e8, "max fee USD");
    }
}
