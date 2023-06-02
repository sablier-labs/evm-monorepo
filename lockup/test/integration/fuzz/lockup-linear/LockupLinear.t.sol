// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierV2Base } from "src/interfaces/ISablierV2Base.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { LockupLinear_Integration_Shared_Test } from "../../shared/lockup-linear/LockupLinear.t.sol";
import { Integration_Test } from "../../Integration.t.sol";
import { Cancel_Integration_Fuzz_Test } from "../lockup/cancel/cancel.t.sol";
import { CancelMultiple_Integration_Fuzz_Test } from "../lockup/cancel-multiple/cancelMultiple.t.sol";
import { GetWithdrawnAmount_Integration_Fuzz_Test } from "../lockup/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { RefundableAmountOf_Integration_Fuzz_Test } from "../lockup/refundable-amount-of/refundableAmountOf.t.sol";
import { Withdraw_Integration_Fuzz_Test } from "../lockup/withdraw/withdraw.t.sol";
import { WithdrawMax_Integration_Fuzz_Test } from "../lockup/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Integration_Fuzz_Test } from "../lockup/withdraw-multiple/withdrawMultiple.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            NON-SHARED ABSTRACT TEST
//////////////////////////////////////////////////////////////////////////*/

/// @notice Common testing logic needed across {SablierV2LockupLinear} integration fuzz tests.
abstract contract LockupLinear_Integration_Fuzz_Test is Integration_Test, LockupLinear_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, LockupLinear_Integration_Shared_Test) {
        // Both of these contracts inherit from {Base_Test}, which is fine because multiple inheritance is
        // allowed in Solidity, and {Base_Test-setUp} will only be called once.
        Integration_Test.setUp();
        LockupLinear_Integration_Shared_Test.setUp();

        // Cast the lockupLinear contract as {ISablierV2Base} and {ISablierV2Lockup}.
        base = ISablierV2Base(lockupLinear);
        lockup = ISablierV2Lockup(lockupLinear);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    Cancel_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Fuzz_Test, Cancel_Integration_Fuzz_Test) {
        LockupLinear_Integration_Fuzz_Test.setUp();
        Cancel_Integration_Fuzz_Test.setUp();
    }
}

contract CancelMultiple_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    CancelMultiple_Integration_Fuzz_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Fuzz_Test, CancelMultiple_Integration_Fuzz_Test)
    {
        LockupLinear_Integration_Fuzz_Test.setUp();
        CancelMultiple_Integration_Fuzz_Test.setUp();
    }
}

contract GetWithdrawnAmount_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    GetWithdrawnAmount_Integration_Fuzz_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Fuzz_Test, GetWithdrawnAmount_Integration_Fuzz_Test)
    {
        LockupLinear_Integration_Fuzz_Test.setUp();
        GetWithdrawnAmount_Integration_Fuzz_Test.setUp();
    }
}

contract RefundableAmountOf_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    RefundableAmountOf_Integration_Fuzz_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Fuzz_Test, RefundableAmountOf_Integration_Fuzz_Test)
    {
        LockupLinear_Integration_Fuzz_Test.setUp();
        RefundableAmountOf_Integration_Fuzz_Test.setUp();
    }
}

contract Withdraw_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    Withdraw_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Fuzz_Test, Withdraw_Integration_Fuzz_Test) {
        LockupLinear_Integration_Fuzz_Test.setUp();
        Withdraw_Integration_Fuzz_Test.setUp();
    }
}

contract WithdrawMax_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    WithdrawMax_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Fuzz_Test, WithdrawMax_Integration_Fuzz_Test) {
        LockupLinear_Integration_Fuzz_Test.setUp();
        WithdrawMax_Integration_Fuzz_Test.setUp();
    }
}

contract WithdrawMultiple_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Fuzz_Test,
    WithdrawMultiple_Integration_Fuzz_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Fuzz_Test, WithdrawMultiple_Integration_Fuzz_Test)
    {
        LockupLinear_Integration_Fuzz_Test.setUp();
        WithdrawMultiple_Integration_Fuzz_Test.setUp();
    }
}
