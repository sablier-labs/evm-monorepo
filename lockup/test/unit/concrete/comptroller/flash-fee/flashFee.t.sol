// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Base_Test } from "../../../../Base.t.sol";

contract FlashFee_Unit_Concrete_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy V2 Core.
        deployCoreConditionally();

        // Make the Admin the default caller in this test suite.
        vm.startPrank({ msgSender: users.admin });
    }

    function test_FlashFee_Zero() external {
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = ZERO;
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }

    function test_FlashFee() external {
        comptroller.setFlashFee(defaults.FLASH_FEE());
        UD60x18 actualFlashFee = comptroller.flashFee();
        UD60x18 expectedFlashFee = defaults.FLASH_FEE();
        assertEq(actualFlashFee, expectedFlashFee, "flashFee");
    }
}
