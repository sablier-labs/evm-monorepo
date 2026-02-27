// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/types/Lockup.sol";

import { Integration_Test } from "../../Integration.t.sol";
import { Cancel_Integration_Concrete_Test } from "../lockup/cancel/cancel.t.sol";
import { RefundableAmountOf_Integration_Concrete_Test } from "../lockup/refundable-amount-of/refundableAmountOf.t.sol";
import { Renounce_Integration_Concrete_Test } from "../lockup/renounce/renounce.t.sol";

abstract contract Lockup_PriceGated_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override {
        Integration_Test.setUp();

        lockupModel = Lockup.Model.LOCKUP_PRICE_GATED;

        initializeDefaultStreams();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_Lockup_PriceGated_Integration_Concrete_Test is
    Lockup_PriceGated_Integration_Concrete_Test,
    Cancel_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_PriceGated_Integration_Concrete_Test, Integration_Test) {
        Lockup_PriceGated_Integration_Concrete_Test.setUp();
    }
}

contract RefundableAmountOf_Lockup_PriceGated_Integration_Concrete_Test is
    Lockup_PriceGated_Integration_Concrete_Test,
    RefundableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_PriceGated_Integration_Concrete_Test, Integration_Test) {
        Lockup_PriceGated_Integration_Concrete_Test.setUp();
    }
}

contract Renounce_Lockup_PriceGated_Integration_Concrete_Test is
    Lockup_PriceGated_Integration_Concrete_Test,
    Renounce_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_PriceGated_Integration_Concrete_Test, Integration_Test) {
        Lockup_PriceGated_Integration_Concrete_Test.setUp();
    }
}
