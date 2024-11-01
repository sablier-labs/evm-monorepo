// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupLinear_Integration_Shared_Test, Integration_Test } from "../../shared/lockup-linear/LockupLinear.t.sol";
import { Cancel_Integration_Fuzz_Test } from "../lockup/cancel.t.sol";
import { CancelMultiple_Integration_Fuzz_Test } from "../lockup/cancelMultiple.t.sol";
import { GetWithdrawnAmount_Integration_Fuzz_Test } from "../lockup/getWithdrawnAmount.t.sol";
import { RefundableAmountOf_Integration_Fuzz_Test } from "../lockup/refundableAmountOf.t.sol";
import { Withdraw_Integration_Fuzz_Test } from "../lockup/withdraw.t.sol";
import { WithdrawMax_Integration_Fuzz_Test } from "../lockup/withdrawMax.t.sol";
import { WithdrawMaxAndTransfer_Integration_Fuzz_Test } from "../lockup/withdrawMaxAndTransfer.t.sol";
import { WithdrawMultiple_Integration_Fuzz_Test } from "../lockup/withdrawMultiple.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    Cancel_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }
}

contract CancelMultiple_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    CancelMultiple_Integration_Fuzz_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Shared_Test, CancelMultiple_Integration_Fuzz_Test)
    {
        LockupLinear_Integration_Shared_Test.setUp();
        CancelMultiple_Integration_Fuzz_Test.setUp();
    }
}

contract GetWithdrawnAmount_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    GetWithdrawnAmount_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }
}

contract RefundableAmountOf_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    RefundableAmountOf_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }
}

contract Withdraw_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    Withdraw_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMax_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    WithdrawMax_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMaxAndTransfer_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    WithdrawMaxAndTransfer_Integration_Fuzz_Test
{
    function setUp() public virtual override(LockupLinear_Integration_Shared_Test, Integration_Test) {
        LockupLinear_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMultiple_LockupLinear_Integration_Fuzz_Test is
    LockupLinear_Integration_Shared_Test,
    WithdrawMultiple_Integration_Fuzz_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Shared_Test, WithdrawMultiple_Integration_Fuzz_Test)
    {
        LockupLinear_Integration_Shared_Test.setUp();
        WithdrawMultiple_Integration_Fuzz_Test.setUp();
    }
}
