// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2Base } from "src/interfaces/ISablierV2Base.sol";
import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";

import { Dynamic_Integration_Shared_Test } from "../../shared/lockup-dynamic/Dynamic.t.sol";
import { Integration_Test } from "../../Integration.t.sol";
import { Burn_Integration_Basic_Test } from "../lockup/burn/burn.t.sol";
import { Cancel_Integration_Basic_Test } from "../lockup/cancel/cancel.t.sol";
import { CancelMultiple_Integration_Basic_Test } from "../lockup/cancel-multiple/cancelMultiple.t.sol";
import { ClaimProtocolRevenues_Integration_Basic_Test } from
    "../lockup/claim-protocol-revenues/claimProtocolRevenues.t.sol";
import { GetAsset_Integration_Basic_Test } from "../lockup/get-asset/getAsset.t.sol";
import { GetDepositedAmount_Integration_Basic_Test } from "../lockup/get-deposited-amount/getDepositedAmount.t.sol";
import { GetEndTime_Integration_Basic_Test } from "../lockup/get-end-time/getEndTime.t.sol";
import { ProtocolRevenues_Integration_Basic_Test } from "../lockup/protocol-revenues/protocolRevenues.t.sol";
import { GetRecipient_Integration_Basic_Test } from "../lockup/get-recipient/getRecipient.t.sol";
import { GetRefundedAmount_Integration_Basic_Test } from "../lockup/get-refunded-amount/getRefundedAmount.t.sol";
import { GetSender_Integration_Basic_Test } from "../lockup/get-sender/getSender.t.sol";
import { GetStartTime_Integration_Basic_Test } from "../lockup/get-start-time/getStartTime.t.sol";
import { GetWithdrawnAmount_Integration_Basic_Test } from "../lockup/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { IsCancelable_Integration_Basic_Test } from "../lockup/is-cancelable/isCancelable.t.sol";
import { IsCold_Integration_Basic_Test } from "../lockup/is-cold/isCold.t.sol";
import { IsDepleted_Integration_Basic_Test } from "../lockup/is-depleted/isDepleted.t.sol";
import { IsStream_Integration_Basic_Test } from "../lockup/is-stream/isStream.t.sol";
import { IsWarm_Integration_Basic_Test } from "../lockup/is-warm/isWarm.t.sol";
import { RefundableAmountOf_Integration_Basic_Test } from "../lockup/refundable-amount-of/refundableAmountOf.t.sol";
import { Renounce_Integration_Basic_Test } from "../lockup/renounce/renounce.t.sol";
import { SetComptroller_Integration_Basic_Test } from "../lockup/set-comptroller/setComptroller.t.sol";
import { SetNFTDescriptor_Integration_Basic_Test } from "../lockup/set-nft-descriptor/setNFTDescriptor.t.sol";
import { StatusOf_Integration_Basic_Test } from "../lockup/status-of/statusOf.t.sol";
import { TokenURI_Integration_Basic_Test } from "../lockup/token-uri/tokenURI.t.sol";
import { Withdraw_Integration_Basic_Test } from "../lockup/withdraw/withdraw.t.sol";
import { WasCanceled_Integration_Basic_Test } from "../lockup/was-canceled/wasCanceled.t.sol";
import { WithdrawMax_Integration_Basic_Test } from "../lockup/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Integration_Basic_Test } from "../lockup/withdraw-multiple/withdrawMultiple.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                            NON-SHARED ABSTRACT TEST
//////////////////////////////////////////////////////////////////////////*/

/// @title Dynamic_Integration_Basic_Test
/// @notice Common testing logic needed across {SablierV2LockupDynamic} integration basic tests.
abstract contract Dynamic_Integration_Basic_Test is Integration_Test, Dynamic_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Dynamic_Integration_Shared_Test) {
        // Both of these contracts inherit from {Base_Test}, which is fine because multiple inheritance is
        // allowed in Solidity, and {Base_Test-setUp} will only be called once.
        Integration_Test.setUp();
        Dynamic_Integration_Shared_Test.setUp();

        // Cast the linear contract as {ISablierV2Base} and {ISablierV2Lockup}.
        base = ISablierV2Lockup(dynamic);
        lockup = ISablierV2Lockup(dynamic);
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract Burn_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, Burn_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, Burn_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        Burn_Integration_Basic_Test.setUp();
    }
}

contract Cancel_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, Cancel_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, Cancel_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        Cancel_Integration_Basic_Test.setUp();
    }
}

contract CancelMultiple_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    CancelMultiple_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, CancelMultiple_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        CancelMultiple_Integration_Basic_Test.setUp();
    }
}

contract ClaimProtocolRevenues_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    ClaimProtocolRevenues_Integration_Basic_Test
{
    function setUp()
        public
        virtual
        override(Dynamic_Integration_Basic_Test, ClaimProtocolRevenues_Integration_Basic_Test)
    {
        Dynamic_Integration_Basic_Test.setUp();
        ClaimProtocolRevenues_Integration_Basic_Test.setUp();
    }
}

contract GetAsset_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, GetAsset_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, GetAsset_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        GetAsset_Integration_Basic_Test.setUp();
    }
}

contract GetDepositedAmount_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetDepositedAmount_Integration_Basic_Test
{
    function setUp()
        public
        virtual
        override(Dynamic_Integration_Basic_Test, GetDepositedAmount_Integration_Basic_Test)
    {
        Dynamic_Integration_Basic_Test.setUp();
        GetDepositedAmount_Integration_Basic_Test.setUp();
    }
}

contract GetEndTime_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetEndTime_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, GetEndTime_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        GetEndTime_Integration_Basic_Test.setUp();
    }
}

contract GetRecipient_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetRecipient_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, GetRecipient_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        GetRecipient_Integration_Basic_Test.setUp();
    }
}

contract GetRefundedAmount_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetRefundedAmount_Integration_Basic_Test
{
    function setUp()
        public
        virtual
        override(Dynamic_Integration_Basic_Test, GetRefundedAmount_Integration_Basic_Test)
    {
        Dynamic_Integration_Basic_Test.setUp();
        GetRefundedAmount_Integration_Basic_Test.setUp();
    }
}

contract ProtocolRevenues_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    ProtocolRevenues_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, ProtocolRevenues_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        ProtocolRevenues_Integration_Basic_Test.setUp();
    }
}

contract RefundableAmountOf_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    RefundableAmountOf_Integration_Basic_Test
{
    function setUp()
        public
        virtual
        override(Dynamic_Integration_Basic_Test, RefundableAmountOf_Integration_Basic_Test)
    {
        Dynamic_Integration_Basic_Test.setUp();
        RefundableAmountOf_Integration_Basic_Test.setUp();
    }
}

contract GetSender_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetSender_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, GetSender_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        GetSender_Integration_Basic_Test.setUp();
    }
}

contract GetStartTime_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetStartTime_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, GetStartTime_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        GetStartTime_Integration_Basic_Test.setUp();
    }
}

contract GetWithdrawnAmount_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    GetWithdrawnAmount_Integration_Basic_Test
{
    function setUp()
        public
        virtual
        override(Dynamic_Integration_Basic_Test, GetWithdrawnAmount_Integration_Basic_Test)
    {
        Dynamic_Integration_Basic_Test.setUp();
        GetWithdrawnAmount_Integration_Basic_Test.setUp();
    }
}

contract IsCancelable_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    IsCancelable_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, IsCancelable_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        IsCancelable_Integration_Basic_Test.setUp();
    }
}

contract IsCold_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, IsCold_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, IsCold_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        IsCold_Integration_Basic_Test.setUp();
    }
}

contract IsDepleted_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    IsDepleted_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, IsDepleted_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        IsDepleted_Integration_Basic_Test.setUp();
    }
}

contract IsStream_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, IsStream_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, IsStream_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        IsStream_Integration_Basic_Test.setUp();
    }
}

contract IsWarm_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, IsWarm_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, IsWarm_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        IsWarm_Integration_Basic_Test.setUp();
    }
}

contract Renounce_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, Renounce_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, Renounce_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        Renounce_Integration_Basic_Test.setUp();
    }
}

contract SetComptroller_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    SetComptroller_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, SetComptroller_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        SetComptroller_Integration_Basic_Test.setUp();
    }
}

contract SetNFTDescriptor_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    SetNFTDescriptor_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, SetNFTDescriptor_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        SetNFTDescriptor_Integration_Basic_Test.setUp();
    }
}

contract StatusOf_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, StatusOf_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, StatusOf_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        StatusOf_Integration_Basic_Test.setUp();
    }
}

contract TokenURI_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, TokenURI_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, TokenURI_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        TokenURI_Integration_Basic_Test.setUp();
    }
}

contract WasCanceled_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    WasCanceled_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, WasCanceled_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        WasCanceled_Integration_Basic_Test.setUp();
    }
}

contract Withdraw_Dynamic_Integration_Basic_Test is Dynamic_Integration_Basic_Test, Withdraw_Integration_Basic_Test {
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, Withdraw_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        Withdraw_Integration_Basic_Test.setUp();
    }
}

contract WithdrawMax_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    WithdrawMax_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, WithdrawMax_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        WithdrawMax_Integration_Basic_Test.setUp();
    }
}

contract WithdrawMultiple_Dynamic_Integration_Basic_Test is
    Dynamic_Integration_Basic_Test,
    WithdrawMultiple_Integration_Basic_Test
{
    function setUp() public virtual override(Dynamic_Integration_Basic_Test, WithdrawMultiple_Integration_Basic_Test) {
        Dynamic_Integration_Basic_Test.setUp();
        WithdrawMultiple_Integration_Basic_Test.setUp();
    }
}
