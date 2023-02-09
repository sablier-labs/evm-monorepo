// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2Config } from "src/interfaces/ISablierV2Config.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Pro_Shared_Test } from "../../../shared/lockup/pro/Pro.t.sol";
import { Fuzz_Test } from "../../Fuzz.t.sol";
import { Cancel_Fuzz_Test } from "../shared/cancel/cancel.t.sol";
import { GetWithdrawnAmount_Fuzz_Test } from "../shared/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { ReturnableAmountOf_Fuzz_Test } from "../shared/returnable-amount-of/returnableAmountOf.t.sol";
import { Withdraw_Fuzz_Test } from "../shared/withdraw/withdraw.t.sol";
import { WithdrawMax_Fuzz_Test } from "../shared/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Fuzz_Test } from "../shared/withdraw-multiple/withdrawMultiple.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            NON-SHARED ABSTRACT TEST
//////////////////////////////////////////////////////////////////////////*/

/// @title Pro_Fuzz_Test
/// @notice Common testing logic needed across {SablierV2LockupPro} fuzz tests.
abstract contract Pro_Fuzz_Test is Fuzz_Test, Pro_Shared_Test {
    function setUp() public virtual override(Fuzz_Test, Pro_Shared_Test) {
        // Both of these contracts inherit from {Base_Test}, but this is fine because multiple inheritance is
        // allowed in Solidity, and {Base_Test-setUp} will only be called once.
        Fuzz_Test.setUp();
        Pro_Shared_Test.setUp();

        // Cast the pro contract as {ISablierV2Config} and {ISablierV2Lockup}.
        config = ISablierV2Config(pro);
        lockup = ISablierV2Lockup(pro);

        // Set the default protocol fee.
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: DEFAULT_PROTOCOL_FEE });
        comptroller.setProtocolFee({ asset: IERC20(address(nonCompliantAsset)), newProtocolFee: DEFAULT_PROTOCOL_FEE });

        // Make the sender the default caller in this test suite.
        changePrank({ who: users.sender });
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Cancel_Pro_Fuzz_Test is Pro_Fuzz_Test, Cancel_Fuzz_Test {
    function setUp() public virtual override(Pro_Fuzz_Test, Cancel_Fuzz_Test) {
        Pro_Fuzz_Test.setUp();
        Cancel_Fuzz_Test.setUp();
    }
}

contract ReturnableAmountOf_Pro_Fuzz_Test is Pro_Fuzz_Test, ReturnableAmountOf_Fuzz_Test {
    function setUp() public virtual override(Pro_Fuzz_Test, ReturnableAmountOf_Fuzz_Test) {
        Pro_Fuzz_Test.setUp();
        ReturnableAmountOf_Fuzz_Test.setUp();
    }
}

contract GetWithdrawnAmount_Pro_Fuzz_Test is Pro_Fuzz_Test, GetWithdrawnAmount_Fuzz_Test {
    function setUp() public virtual override(Pro_Fuzz_Test, GetWithdrawnAmount_Fuzz_Test) {
        Pro_Fuzz_Test.setUp();
        GetWithdrawnAmount_Fuzz_Test.setUp();
    }
}

contract WithdrawMax_Pro_Fuzz_Test is Pro_Fuzz_Test, WithdrawMax_Fuzz_Test {
    function setUp() public virtual override(Pro_Fuzz_Test, WithdrawMax_Fuzz_Test) {
        Pro_Fuzz_Test.setUp();
        WithdrawMax_Fuzz_Test.setUp();
    }
}

contract WithdrawMultiple_Pro_Fuzz_Test is Pro_Fuzz_Test, WithdrawMultiple_Fuzz_Test {
    function setUp() public virtual override(Pro_Fuzz_Test, WithdrawMultiple_Fuzz_Test) {
        Pro_Fuzz_Test.setUp();
        WithdrawMultiple_Fuzz_Test.setUp();
    }
}
