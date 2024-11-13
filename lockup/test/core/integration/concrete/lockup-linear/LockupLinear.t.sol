// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Integration_Test } from "./../../Integration.t.sol";
import { Lockup_Linear_Integration_Shared_Test } from "./../../shared/lockup/LockupLinear.t.sol";
import { AllowToHook_Integration_Concrete_Test } from "./../lockup-base/allow-to-hook/allowToHook.t.sol";
import { Batch_Integration_Concrete_Test } from "./../lockup-base/batch/batch.t.sol";
import { Burn_Integration_Concrete_Test } from "./../lockup-base/burn/burn.t.sol";
import { CancelMultiple_Integration_Concrete_Test } from "./../lockup-base/cancel-multiple/cancelMultiple.t.sol";
import { Cancel_Integration_Concrete_Test } from "./../lockup-base/cancel/cancel.t.sol";
import { GetAsset_Integration_Concrete_Test } from "./../lockup-base/get-asset/getAsset.t.sol";
import { GetDepositedAmount_Integration_Concrete_Test } from
    "./../lockup-base/get-deposited-amount/getDepositedAmount.t.sol";
import { GetEndTime_Integration_Concrete_Test } from "./../lockup-base/get-end-time/getEndTime.t.sol";
import { GetRecipient_Integration_Concrete_Test } from "./../lockup-base/get-recipient/getRecipient.t.sol";
import { GetRefundedAmount_Integration_Concrete_Test } from
    "./../lockup-base/get-refunded-amount/getRefundedAmount.t.sol";
import { GetSender_Integration_Concrete_Test } from "./../lockup-base/get-sender/getSender.t.sol";
import { GetStartTime_Integration_Concrete_Test } from "./../lockup-base/get-start-time/getStartTime.t.sol";
import { GetWithdrawnAmount_Integration_Concrete_Test } from
    "./../lockup-base/get-withdrawn-amount/getWithdrawnAmount.t.sol";
import { IsAllowedToHook_Integration_Concrete_Test } from "./../lockup-base/is-allowed-to-hook/isAllowedToHook.t.sol";
import { IsCancelable_Integration_Concrete_Test } from "./../lockup-base/is-cancelable/isCancelable.t.sol";
import { IsCold_Integration_Concrete_Test } from "./../lockup-base/is-cold/isCold.t.sol";
import { IsDepleted_Integration_Concrete_Test } from "./../lockup-base/is-depleted/isDepleted.t.sol";
import { IsStream_Integration_Concrete_Test } from "./../lockup-base/is-stream/isStream.t.sol";
import { IsTransferable_Integration_Concrete_Test } from "./../lockup-base/is-transferable/isTransferable.t.sol";
import { IsWarm_Integration_Concrete_Test } from "./../lockup-base/is-warm/isWarm.t.sol";
import { RefundableAmountOf_Integration_Concrete_Test } from
    "./../lockup-base/refundable-amount-of/refundableAmountOf.t.sol";
import { Renounce_Integration_Concrete_Test } from "./../lockup-base/renounce/renounce.t.sol";
import { SetNFTDescriptor_Integration_Concrete_Test } from "./../lockup-base/set-nft-descriptor/setNFTDescriptor.t.sol";
import { StatusOf_Integration_Concrete_Test } from "./../lockup-base/status-of/statusOf.t.sol";
import { TransferFrom_Integration_Concrete_Test } from "./../lockup-base/transfer-from/transferFrom.t.sol";
import { WasCanceled_Integration_Concrete_Test } from "./../lockup-base/was-canceled/wasCanceled.t.sol";
import { WithdrawHooks_Integration_Concrete_Test } from "./../lockup-base/withdraw-hooks/withdrawHooks.t.sol";
import { WithdrawMaxAndTransfer_Integration_Concrete_Test } from
    "./../lockup-base/withdraw-max-and-transfer/withdrawMaxAndTransfer.t.sol";
import { WithdrawMax_Integration_Concrete_Test } from "./../lockup-base/withdraw-max/withdrawMax.t.sol";
import { WithdrawMultiple_Integration_Concrete_Test } from "./../lockup-base/withdraw-multiple/withdrawMultiple.t.sol";
import { Withdraw_Integration_Concrete_Test } from "./../lockup-base/withdraw/withdraw.t.sol";

/*//////////////////////////////////////////////////////////////////////////
                                SHARED TESTS
//////////////////////////////////////////////////////////////////////////*/

contract AllowToHook_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    AllowToHook_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract Batch_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    Batch_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract Burn_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    Burn_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract Cancel_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    Cancel_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract CancelMultiple_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    CancelMultiple_Integration_Concrete_Test
{
    modifier whenCallerAuthorizedForAllStreams() override {
        _;
        cancelMultipleStreamIds = WarpAndCreateStreamsForCancelMultipleLL({ warpTime: originalTime });
        _;
    }

    function setUp()
        public
        virtual
        override(Lockup_Linear_Integration_Shared_Test, CancelMultiple_Integration_Concrete_Test)
    {
        Lockup_Linear_Integration_Shared_Test.setUp();
        CancelMultiple_Integration_Concrete_Test.setUp();
    }
}

contract GetAsset_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetAsset_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetDepositedAmount_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetDepositedAmount_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetEndTime_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetEndTime_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetRecipient_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetRecipient_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetRefundedAmount_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetRefundedAmount_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetSender_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetSender_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetStartTime_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetStartTime_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract GetWithdrawnAmount_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    GetWithdrawnAmount_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsAllowedToHook_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsAllowedToHook_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsCancelable_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsCancelable_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsCold_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsCold_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsDepleted_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsDepleted_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsStream_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsStream_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsTransferable_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsTransferable_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract IsWarm_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    IsWarm_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract Renounce_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    Renounce_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract RefundableAmountOf_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    RefundableAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract SetNFTDescriptor_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    SetNFTDescriptor_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract StatusOf_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    StatusOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract TransferFrom_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    TransferFrom_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(Lockup_Linear_Integration_Shared_Test, TransferFrom_Integration_Concrete_Test)
    {
        Lockup_Linear_Integration_Shared_Test.setUp();
        TransferFrom_Integration_Concrete_Test.setUp();
    }
}

contract WasCanceled_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    WasCanceled_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract Withdraw_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    Withdraw_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract WithdrawHooks_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    WithdrawHooks_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(Lockup_Linear_Integration_Shared_Test, WithdrawHooks_Integration_Concrete_Test)
    {
        Lockup_Linear_Integration_Shared_Test.setUp();
        WithdrawHooks_Integration_Concrete_Test.setUp();
    }
}

contract WithdrawMax_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    WithdrawMax_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMaxAndTransfer_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    WithdrawMaxAndTransfer_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Shared_Test, Integration_Test) {
        Lockup_Linear_Integration_Shared_Test.setUp();
    }
}

contract WithdrawMultiple_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Shared_Test,
    WithdrawMultiple_Integration_Concrete_Test
{
    /// @dev This modifier runs the test in three different modes:
    /// - Stream's sender as caller
    /// - Stream's recipient as caller
    /// - Approved NFT operator as caller
    modifier whenCallerAuthorizedForAllStreams() override {
        caller = users.sender;
        _;

        withdrawMultipleStreamIds = WarpAndCreateStreamsWithdrawMultipleLL({ warpTime: originalTime });
        caller = users.recipient;
        _;

        withdrawMultipleStreamIds = WarpAndCreateStreamsWithdrawMultipleLL({ warpTime: originalTime });
        caller = users.operator;
        _;
    }

    function setUp()
        public
        virtual
        override(Lockup_Linear_Integration_Shared_Test, WithdrawMultiple_Integration_Concrete_Test)
    {
        Lockup_Linear_Integration_Shared_Test.setUp();
        WithdrawMultiple_Integration_Concrete_Test.setUp();
    }
}
