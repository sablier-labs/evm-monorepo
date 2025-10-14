// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/Lockup.sol";

import { Integration_Test } from "../../Integration.t.sol";
import { Cancel_Integration_Fuzz_Test } from "./../lockup/cancel.t.sol";
import { RefundableAmountOf_Integration_Fuzz_Test } from "./../lockup/refundableAmountOf.t.sol";

abstract contract Lockup_Dynamic_Integration_Fuzz_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        lockupModel = Lockup.Model.LOCKUP_DYNAMIC;
        initializeDefaultStreams();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_Lockup_Dynamic_Integration_Fuzz_Test is
    Lockup_Dynamic_Integration_Fuzz_Test,
    Cancel_Integration_Fuzz_Test
{
    function setUp() public virtual override(Lockup_Dynamic_Integration_Fuzz_Test, Integration_Test) {
        Lockup_Dynamic_Integration_Fuzz_Test.setUp();
    }
}

contract RefundableAmountOf_Lockup_Dynamic_Integration_Fuzz_Test is
    Lockup_Dynamic_Integration_Fuzz_Test,
    RefundableAmountOf_Integration_Fuzz_Test
{
    function setUp() public virtual override(Lockup_Dynamic_Integration_Fuzz_Test, Integration_Test) {
        Lockup_Dynamic_Integration_Fuzz_Test.setUp();
    }
}
