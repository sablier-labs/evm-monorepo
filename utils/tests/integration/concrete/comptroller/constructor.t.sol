// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";

import { Base_Test } from "tests/Base.t.sol";

contract Constructor_Comptroller_Concrete_Test is Base_Test {
    function test_Constructor() public view {
        assertEq(comptroller.admin(), admin, "admin");
        assertEq(comptroller.MAX_FEE_USD(), MAX_FEE_USD, "max fee USD");
        bytes4 expectedMinimalInterfaceId = ISablierComptroller.calculateMinFeeWeiFor.selector
            ^ ISablierComptroller.convertUSDFeeToWei.selector ^ ISablierComptroller.execute.selector
            ^ ISablierComptroller.getMinFeeUSDFor.selector;
        assertEq(comptroller.MINIMAL_INTERFACE_ID(), expectedMinimalInterfaceId, "minimal interface ID");
        assertEq(comptroller.oracle(), address(oracle), "oracle");
    }
}
