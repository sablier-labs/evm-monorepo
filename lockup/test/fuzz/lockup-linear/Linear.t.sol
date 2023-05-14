// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2Base } from "src/interfaces/ISablierV2Base.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Linear_Shared_Test } from "../../shared/lockup-linear/Linear.t.sol";
import { Fuzz_Test } from "../Fuzz.t.sol";
import { Cancel_Fuzz_Test } from "../lockup/cancel/cancel.t.sol";
import { CancelMultiple_Fuzz_Test } from "../lockup/cancel-multiple/cancelMultiple.t.sol";
import { GetWithdrawnAmount_Fuzz_Test } from "../lockup/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { RefundableAmountOf_Fuzz_Test } from "../lockup/refundable-amount-of/refundableAmountOf.t.sol";
import { Withdraw_Fuzz_Test } from "../lockup/withdraw/withdraw.t.sol";
import { WithdrawMax_Fuzz_Test } from "../lockup/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Fuzz_Test } from "../lockup/withdraw-multiple/withdrawMultiple.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            NON-SHARED ABSTRACT TEST
//////////////////////////////////////////////////////////////////////////*/

/// @title Linear_Fuzz_Test
/// @notice Common testing logic needed across {SablierV2LockupLinear} fuzz tests.
abstract contract Linear_Fuzz_Test is Fuzz_Test, Linear_Shared_Test {
    function setUp() public virtual override(Fuzz_Test, Linear_Shared_Test) {
        // Both of these contracts inherit from {Base_Test}, which is fine because multiple inheritance is
        // allowed in Solidity, and {Base_Test-setUp} will only be called once.
        Fuzz_Test.setUp();
        Linear_Shared_Test.setUp();

        // Cast the linear contract as {ISablierV2Base} and {ISablierV2Lockup}.
        base = ISablierV2Base(linear);
        lockup = ISablierV2Lockup(linear);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_Linear_Fuzz_Test is Linear_Fuzz_Test, Cancel_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, Cancel_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        Cancel_Fuzz_Test.setUp();
    }
}

contract CancelMultiple_Linear_Fuzz_Test is Linear_Fuzz_Test, CancelMultiple_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, CancelMultiple_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        CancelMultiple_Fuzz_Test.setUp();
    }
}

contract GetWithdrawnAmount_Linear_Fuzz_Test is Linear_Fuzz_Test, GetWithdrawnAmount_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, GetWithdrawnAmount_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        GetWithdrawnAmount_Fuzz_Test.setUp();
    }
}

contract RefundableAmountOf_Linear_Fuzz_Test is Linear_Fuzz_Test, RefundableAmountOf_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, RefundableAmountOf_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        RefundableAmountOf_Fuzz_Test.setUp();
    }
}

contract Withdraw_Linear_Fuzz_Test is Linear_Fuzz_Test, Withdraw_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, Withdraw_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        Withdraw_Fuzz_Test.setUp();
    }
}

contract WithdrawMax_Linear_Fuzz_Test is Linear_Fuzz_Test, WithdrawMax_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, WithdrawMax_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        WithdrawMax_Fuzz_Test.setUp();
    }
}

contract WithdrawMultiple_Linear_Fuzz_Test is Linear_Fuzz_Test, WithdrawMultiple_Fuzz_Test {
    function setUp() public virtual override(Linear_Fuzz_Test, WithdrawMultiple_Fuzz_Test) {
        Linear_Fuzz_Test.setUp();
        WithdrawMultiple_Fuzz_Test.setUp();
    }
}
