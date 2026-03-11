// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ILidoWithdrawalQueue } from "src/interfaces/external/ILidoWithdrawalQueue.sol";
import { IWstETH } from "src/interfaces/external/IWstETH.sol";
import { ISablierLidoAdapter } from "src/interfaces/ISablierLidoAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract RequestLidoWithdrawal_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                EvmUtilsErrors.Comptrollerable_CallerNotComptroller.selector, address(comptroller), users.depositor
            )
        );
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);
    }

    function test_RevertGiven_ACTIVEStatus() external whenCallerComptroller {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_VaultActive.selector, vaultIds.vaultWithAdapter)
        );
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);
    }

    function test_RevertGiven_AlreadyUnstaked() external whenCallerComptroller givenNotACTIVEStatus {
        // Unstake via Curve path first.
        bob.unstakeTokensViaAdapter(vaultIds.vaultWithAdapter);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_VaultAlreadyUnstaked.selector, vaultIds.vaultWithAdapter)
        );
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);
    }

    function test_RevertGiven_LidoWithdrawalRequested()
        external
        whenCallerComptroller
        givenNotACTIVEStatus
        givenNotAlreadyUnstaked
    {
        // Request a Lido withdrawal so it reverts on the second request.
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_LidoWithdrawalAlreadyRequested.selector, vaultIds.vaultWithAdapter
            )
        );
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);
    }

    function test_RevertGiven_TotalWstETHZero()
        external
        whenCallerComptroller
        givenNotACTIVEStatus
        givenNotAlreadyUnstaked
        givenLidoWithdrawalNotRequested
    {
        // Create a vault with adapter but no deposits (wstETH balance is zero).
        vm.warp(FEB_1_2026);
        uint256 emptyVaultId = createVaultWithAdapter();
        vm.warp(EXPIRY);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLidoAdapter_NoWstETHToWithdraw.selector, emptyVaultId));
        adapter.requestLidoWithdrawal(emptyVaultId);
    }

    function test_RevertGiven_AmountNotExceedMinPerRequest()
        external
        whenCallerComptroller
        givenNotACTIVEStatus
        givenNotAlreadyUnstaked
        givenLidoWithdrawalNotRequested
        givenTotalWstETHNotZero
    {
        // Create a new vault with adapter and deposit the dust amount.
        uint128 dustAmount = LIDO_MIN_STETH_WITHDRAWAL_AMOUNT - 1;
        (uint256 vaultId,, uint256 expectedTotalStETHReceived) = _createVaultAndDeposit({ depositAmount: dustAmount });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_WithdrawalAmountBelowMinimum.selector,
                vaultId,
                expectedTotalStETHReceived,
                LIDO_MIN_STETH_WITHDRAWAL_AMOUNT
            )
        );

        // Request a Lido withdrawal.
        setMsgSender(address(comptroller));
        adapter.requestLidoWithdrawal(vaultId);
    }

    function test_GivenAmountNotExceedMaxPerRequest()
        external
        whenCallerComptroller
        givenNotACTIVEStatus
        givenNotAlreadyUnstaked
        givenLidoWithdrawalNotRequested
        givenTotalWstETHNotZero
        givenAmountExceedsMinPerRequest
    {
        // It should submit a single withdrawal request.
        uint256[] memory expectedAmounts = new uint256[](1);
        expectedAmounts[0] = DEPOSIT_AMOUNT;

        _requestLidoWithdrawal({
            vaultId: vaultIds.vaultWithAdapter,
            expectedTotalWstETHMinted: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            expectedTotalStETHReceived: DEPOSIT_AMOUNT,
            expectedAmounts: expectedAmounts
        });
    }

    function test_WhenRemainderNotExceedMinPerRequest()
        external
        whenCallerComptroller
        givenNotACTIVEStatus
        givenNotAlreadyUnstaked
        givenLidoWithdrawalNotRequested
        givenTotalWstETHNotZero
        givenAmountExceedsMinPerRequest
        givenAmountExceedsMaxPerRequest
    {
        // Create a new vault with adapter and deposit an amount that leaves a remainder.
        uint128 depositAmount = LIDO_MAX_STETH_WITHDRAWAL_AMOUNT + 10 wei;
        (uint256 vaultId, uint256 expectedTotalWstETHMinted, uint256 expectedTotalStETHReceived) =
            _createVaultAndDeposit(depositAmount);

        // It should adjust the second last and last request amounts.
        uint256[] memory expectedAmounts = new uint256[](2);
        expectedAmounts[0] = expectedTotalStETHReceived - LIDO_MIN_STETH_WITHDRAWAL_AMOUNT;
        expectedAmounts[1] = LIDO_MIN_STETH_WITHDRAWAL_AMOUNT;

        // Test the lido withdrawal request.
        _requestLidoWithdrawal(vaultId, expectedTotalWstETHMinted, expectedTotalStETHReceived, expectedAmounts);
    }

    function test_WhenRemainderExceedsMinPerRequest()
        external
        whenCallerComptroller
        givenNotACTIVEStatus
        givenNotAlreadyUnstaked
        givenLidoWithdrawalNotRequested
        givenTotalWstETHNotZero
        givenAmountExceedsMinPerRequest
        givenAmountExceedsMaxPerRequest
    {
        // Create a new vault with adapter and deposit an amount that exceeds max per request.
        uint128 depositAmount = LIDO_MAX_STETH_WITHDRAWAL_AMOUNT + DEPOSIT_AMOUNT;
        (uint256 vaultId, uint256 expectedTotalWstETHMinted, uint256 expectedTotalStETHReceived) =
            _createVaultAndDeposit(depositAmount);

        // It should have the following expected amounts.
        uint256[] memory expectedAmounts = new uint256[](2);
        expectedAmounts[0] = LIDO_MAX_STETH_WITHDRAWAL_AMOUNT;
        expectedAmounts[1] = expectedTotalStETHReceived - LIDO_MAX_STETH_WITHDRAWAL_AMOUNT;

        // Test the lido withdrawal request.
        _requestLidoWithdrawal(vaultId, expectedTotalWstETHMinted, expectedTotalStETHReceived, expectedAmounts);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Private helper to create a vault with adapter and deposit the given amount.
    function _createVaultAndDeposit(uint128 depositAmount)
        private
        returns (uint256 vaultId, uint256 expectedTotalWstETHMinted, uint256 expectedTotalStETHReceived)
    {
        // Warp back to starting point in time.
        vm.warp(FEB_1_2026);

        // Create a new vault with adapter.
        vaultId = createVaultWithAdapter();

        // Deposit the amount into the newly created vault.
        setMsgSender(users.depositor);
        bob.enter(vaultId, depositAmount);

        // Calculate the total wstETH minted.
        expectedTotalWstETHMinted = ud(depositAmount).mul(WSTETH_WETH_EXCHANGE_RATE).intoUint256();

        // Calculate the expected total stETH that would be received after unstaking.
        expectedTotalStETHReceived = ud(expectedTotalWstETHMinted).div(WSTETH_WETH_EXCHANGE_RATE).intoUint256();

        // Warp past expiry.
        vm.warp(EXPIRY);
    }

    /// @dev Private helper to request a Lido withdrawal and assert the expected results.
    function _requestLidoWithdrawal(
        uint256 vaultId,
        uint256 expectedTotalWstETHMinted,
        uint256 expectedTotalStETHReceived,
        uint256[] memory expectedAmounts
    )
        private
    {
        // Build expected request IDs.
        uint256[] memory expectedRequestIds = new uint256[](expectedAmounts.length);
        for (uint256 i = 0; i < expectedAmounts.length; ++i) {
            expectedRequestIds[i] = i + 1;
        }

        // It should unwrap wstETH to stETH.
        vm.expectCall({ callee: address(wstEth), data: abi.encodeCall(IWstETH.unwrap, (expectedTotalWstETHMinted)) });

        // It should approve Lido withdrawal queue to spend stETH.
        vm.expectCall({
            callee: address(steth),
            data: abi.encodeCall(IERC20.approve, (address(lidoWithdrawalQueue), expectedTotalStETHReceived))
        });

        // It should submit the withdrawal requests.
        vm.expectCall({
            callee: address(lidoWithdrawalQueue),
            data: abi.encodeCall(ILidoWithdrawalQueue.requestWithdrawals, (expectedAmounts, address(adapter)))
        });

        // It should emit a {RequestLidoWithdrawal} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.RequestLidoWithdrawal({
            vaultId: vaultId,
            comptroller: address(comptroller),
            wstETHAmount: expectedTotalWstETHMinted,
            stETHAmount: expectedTotalStETHReceived,
            withdrawalRequestIds: expectedRequestIds
        });

        // Request a Lido withdrawal.
        setMsgSender(address(comptroller));
        adapter.requestLidoWithdrawal(vaultId);

        // It should store the withdrawal request IDs.
        uint256[] memory actualRequestIds = adapter.getLidoWithdrawalRequestIds(vaultId);
        assertEq(actualRequestIds.length, expectedRequestIds.length, "requestIds length");
        for (uint256 i = 0; i < expectedRequestIds.length; ++i) {
            assertEq(actualRequestIds[i], expectedRequestIds[i], "requestIds[i]");
        }
    }
}
