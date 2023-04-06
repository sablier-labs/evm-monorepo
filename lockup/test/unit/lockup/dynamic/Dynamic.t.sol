// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2Base } from "src/interfaces/ISablierV2Base.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Dynamic_Shared_Test } from "../../../shared/lockup/dynamic/Dynamic.t.sol";
import { Unit_Test } from "../../Unit.t.sol";
import { Burn_Unit_Test } from "../shared/burn/burn.t.sol";
import { Cancel_Unit_Test } from "../shared/cancel/cancel.t.sol";
import { CancelMultiple_Unit_Test } from "../shared/cancel-multiple/cancelMultiple.t.sol";
import { ClaimProtocolRevenues_Unit_Test } from "../shared/claim-protocol-revenues/claimProtocolRevenues.t.sol";
import { GetAsset_Unit_Test } from "../shared/get-asset/getAsset.t.sol";
import { GetDepositedAmount_Unit_Test } from "../shared/get-deposited-amount/getDepositedAmount.t.sol";
import { GetEndTime_Unit_Test } from "../shared/get-end-time/getEndTime.t.sol";
import { ProtocolRevenues_Unit_Test } from "../shared/protocol-revenues/protocolRevenues.t.sol";
import { GetRecipient_Unit_Test } from "../shared/get-recipient/getRecipient.t.sol";
import { GetReturnedAmount_Unit_Test } from "../shared/get-returned-amount/getReturnedAmount.t.sol";
import { GetSender_Unit_Test } from "../shared/get-sender/getSender.t.sol";
import { GetStartTime_Unit_Test } from "../shared/get-start-time/getStartTime.t.sol";
import { GetStatus_Unit_Test } from "../shared/get-status/getStatus.t.sol";
import { GetWithdrawnAmount_Unit_Test } from "../shared/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { IsCancelable_Unit_Test } from "../shared/is-cancelable/isCancelable.t.sol";
import { Renounce_Unit_Test } from "../shared/renounce/renounce.t.sol";
import { ReturnableAmountOf_Unit_Test } from "../shared/returnable-amount-of/returnableAmountOf.t.sol";
import { SetComptroller_Unit_Test } from "../shared/set-comptroller/setComptroller.t.sol";
import { SetNFTDescriptor_Unit_Test } from "../shared/set-nft-descriptor/setNFTDescriptor.t.sol";
import { TokenURI_Unit_Test } from "../shared/token-uri/tokenURI.t.sol";
import { Withdraw_Unit_Test } from "../shared/withdraw/withdraw.t.sol";
import { WithdrawMax_Unit_Test } from "../shared/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Unit_Test } from "../shared/withdraw-multiple/withdrawMultiple.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            NON-SHARED ABSTRACT TEST
//////////////////////////////////////////////////////////////////////////*/

/// @title Dynamic_Unit_Test
/// @notice Common testing logic needed across {SablierV2LockupDynamic} unit tests.
abstract contract Dynamic_Unit_Test is Unit_Test, Dynamic_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override(Unit_Test, Dynamic_Shared_Test) {
        // Both of these contracts inherit from {Base_Test}, but this is fine because multiple inheritance is
        // allowed in Solidity, and {Base_Test-setUp} will only be called once.
        Unit_Test.setUp();
        Dynamic_Shared_Test.setUp();

        // Cast the linear contract as {ISablierV2Base} and {ISablierV2Lockup}.
        base = ISablierV2Lockup(dynamic);
        lockup = ISablierV2Lockup(dynamic);

        // Set the default protocol fee.
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: DEFAULT_PROTOCOL_FEE });
        comptroller.setProtocolFee({ asset: IERC20(address(nonCompliantAsset)), newProtocolFee: DEFAULT_PROTOCOL_FEE });

        // Make the sender the default caller in this test suite.
        changePrank({ msgSender: users.sender });
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Burn_Dynamic_Unit_Test is Dynamic_Unit_Test, Burn_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, Burn_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        Burn_Unit_Test.setUp();
    }
}

contract Cancel_Dynamic_Unit_Test is Dynamic_Unit_Test, Cancel_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, Cancel_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        Cancel_Unit_Test.setUp();
    }
}

contract CancelMultiple_Dynamic_Unit_Test is Dynamic_Unit_Test, CancelMultiple_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, CancelMultiple_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        CancelMultiple_Unit_Test.setUp();
    }
}

contract ClaimProtocolRevenues_Dynamic_Unit_Test is Dynamic_Unit_Test, ClaimProtocolRevenues_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, ClaimProtocolRevenues_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        ClaimProtocolRevenues_Unit_Test.setUp();
    }
}

contract GetAsset_Dynamic_Unit_Test is Dynamic_Unit_Test, GetAsset_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetAsset_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetAsset_Unit_Test.setUp();
    }
}

contract GetDepositedAmount_Dynamic_Unit_Test is Dynamic_Unit_Test, GetDepositedAmount_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetDepositedAmount_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetDepositedAmount_Unit_Test.setUp();
    }
}

contract GetEndTime_Dynamic_Unit_Test is Dynamic_Unit_Test, GetEndTime_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetEndTime_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetEndTime_Unit_Test.setUp();
    }
}

contract GetRecipient_Dynamic_Unit_Test is Dynamic_Unit_Test, GetRecipient_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetRecipient_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetRecipient_Unit_Test.setUp();
    }
}

contract GetReturnedAmount_Dynamic_Unit_Test is Dynamic_Unit_Test, GetReturnedAmount_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetReturnedAmount_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetReturnedAmount_Unit_Test.setUp();
    }
}

contract ProtocolRevenues_Dynamic_Unit_Test is Dynamic_Unit_Test, ProtocolRevenues_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, ProtocolRevenues_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        ProtocolRevenues_Unit_Test.setUp();
    }
}

contract ReturnableAmountOf_Dynamic_Unit_Test is Dynamic_Unit_Test, ReturnableAmountOf_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, ReturnableAmountOf_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        ReturnableAmountOf_Unit_Test.setUp();
    }
}

contract GetSender_Dynamic_Unit_Test is Dynamic_Unit_Test, GetSender_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetSender_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetSender_Unit_Test.setUp();
    }
}

contract GetStartTime_Dynamic_Unit_Test is Dynamic_Unit_Test, GetStartTime_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetStartTime_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetStartTime_Unit_Test.setUp();
    }
}

contract GetStatus_Dynamic_Unit_Test is Dynamic_Unit_Test, GetStatus_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetStatus_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetStatus_Unit_Test.setUp();
    }
}

contract GetWithdrawnAmount_Dynamic_Unit_Test is Dynamic_Unit_Test, GetWithdrawnAmount_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, GetWithdrawnAmount_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        GetWithdrawnAmount_Unit_Test.setUp();
    }
}

contract IsCancelable_Dynamic_Unit_Test is Dynamic_Unit_Test, IsCancelable_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, IsCancelable_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        IsCancelable_Unit_Test.setUp();
    }
}

contract Renounce_Dynamic_Unit_Test is Dynamic_Unit_Test, Renounce_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, Renounce_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        Renounce_Unit_Test.setUp();
    }
}

contract SetComptroller_Dynamic_Unit_Test is Dynamic_Unit_Test, SetComptroller_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, SetComptroller_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        SetComptroller_Unit_Test.setUp();
    }
}

contract SetNFTDescriptor_Dynamic_Unit_Test is Dynamic_Unit_Test, SetNFTDescriptor_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, SetNFTDescriptor_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        SetNFTDescriptor_Unit_Test.setUp();
    }
}

contract TokenURI_Dynamic_Unit_Test is Dynamic_Unit_Test, TokenURI_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, TokenURI_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        TokenURI_Unit_Test.setUp();
    }
}

contract Withdraw_Dynamic_Unit_Test is Dynamic_Unit_Test, Withdraw_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, Withdraw_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        Withdraw_Unit_Test.setUp();
    }
}

contract WithdrawMax_Dynamic_Unit_Test is Dynamic_Unit_Test, WithdrawMax_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, WithdrawMax_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        WithdrawMax_Unit_Test.setUp();
    }
}

contract WithdrawMultiple_Dynamic_Unit_Test is Dynamic_Unit_Test, WithdrawMultiple_Unit_Test {
    function setUp() public virtual override(Dynamic_Unit_Test, WithdrawMultiple_Unit_Test) {
        Dynamic_Unit_Test.setUp();
        WithdrawMultiple_Unit_Test.setUp();
    }
}
