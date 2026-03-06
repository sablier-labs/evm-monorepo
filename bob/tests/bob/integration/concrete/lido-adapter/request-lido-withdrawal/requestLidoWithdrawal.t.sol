// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";
import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";

import { ILidoWithdrawalQueue } from "src/interfaces/external/ILidoWithdrawalQueue.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
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

    function test_RevertGiven_LidoWithdrawalRequested() external whenCallerComptroller {
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

    function test_RevertGiven_TotalWstETHZero() external whenCallerComptroller givenLidoWithdrawalNotRequested {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_NoWstETHToWithdraw.selector, vaultIds.defaultVault)
        );
        adapter.requestLidoWithdrawal(vaultIds.defaultVault);
    }

    function test_WhenAmountNotExceedMaxPerRequest()
        external
        whenCallerComptroller
        givenLidoWithdrawalNotRequested
        givenTotalWstETHNotZero
    {
        // It should unwrap wstETH to stETH.
        vm.expectCall({
            callee: address(wstEth),
            data: abi.encodeCall(IWstETH.unwrap, (WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT))
        });

        // It should approve Lido withdrawal queue to spend stETH.
        vm.expectCall({
            callee: address(steth),
            data: abi.encodeCall(IERC20.approve, (address(lidoWithdrawalQueue), DEPOSIT_AMOUNT))
        });

        uint256[] memory expectedAmounts = new uint256[](1);
        expectedAmounts[0] = DEPOSIT_AMOUNT;

        uint256[] memory expectedRequestIds = new uint256[](1);
        expectedRequestIds[0] = 1;

        // It should submit a single withdrawal request.
        vm.expectCall({
            callee: address(lidoWithdrawalQueue),
            data: abi.encodeCall(ILidoWithdrawalQueue.requestWithdrawals, (expectedAmounts, address(adapter)))
        });

        // It should emit a {RequestLidoWithdrawal} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.RequestLidoWithdrawal({
            vaultId: vaultIds.vaultWithAdapter,
            comptroller: address(comptroller),
            wstETHAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            stETHAmount: DEPOSIT_AMOUNT,
            withdrawalRequestIds: expectedRequestIds
        });

        // Request a Lido withdrawal.
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);

        // It should store one withdrawal request ID.
        uint256[] memory storedRequestIds = adapter.getLidoWithdrawalRequestIds(vaultIds.vaultWithAdapter);
        assertEq(storedRequestIds.length, 1, "requestIds length");
        assertEq(storedRequestIds[0], 1, "requestIds[0]");
    }

    function test_WhenAmountExceedsMaxPerRequest()
        external
        whenCallerComptroller
        givenLidoWithdrawalNotRequested
        givenTotalWstETHNotZero
    {
        uint128 largeDepositAmount = 1500 ether;

        // Deposit the WETH into the vault.
        setMsgSender(users.newDepositor);
        vm.deal(users.newDepositor, largeDepositAmount);
        IWETH9(address(weth)).deposit{ value: largeDepositAmount }();
        weth.approve(address(bob), largeDepositAmount);
        bob.enter(vaultIds.vaultWithAdapter, largeDepositAmount);

        // Calculate expected values.
        uint128 totalWstETH =
            WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT + ud(largeDepositAmount).mul(WSTETH_WETH_EXCHANGE_RATE).intoUint128();
        uint256 expectedStETHAmount = DEPOSIT_AMOUNT + largeDepositAmount;

        // Change the caller to the comptroller.
        setMsgSender(address(comptroller));

        // It should unwrap wstETH to stETH.
        vm.expectCall({ callee: address(wstEth), data: abi.encodeCall(IWstETH.unwrap, (totalWstETH)) });

        // It should approve Lido withdrawal queue to spend stETH.
        vm.expectCall({
            callee: address(steth),
            data: abi.encodeCall(IERC20.approve, (address(lidoWithdrawalQueue), expectedStETHAmount))
        });

        uint256 maxPerRequest = lidoWithdrawalQueue.MAX_STETH_WITHDRAWAL_AMOUNT();
        uint256[] memory expectedAmounts = new uint256[](2);
        expectedAmounts[0] = maxPerRequest;
        expectedAmounts[1] = expectedStETHAmount - maxPerRequest;

        uint256[] memory expectedRequestIds = new uint256[](2);
        expectedRequestIds[0] = 1;
        expectedRequestIds[1] = 2;

        // It should split into multiple withdrawal requests.
        vm.expectCall({
            callee: address(lidoWithdrawalQueue),
            data: abi.encodeCall(ILidoWithdrawalQueue.requestWithdrawals, (expectedAmounts, address(adapter)))
        });

        // It should emit a {RequestLidoWithdrawal} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierLidoAdapter.RequestLidoWithdrawal({
            vaultId: vaultIds.vaultWithAdapter,
            comptroller: address(comptroller),
            wstETHAmount: totalWstETH,
            stETHAmount: expectedStETHAmount,
            withdrawalRequestIds: expectedRequestIds
        });

        // Request a Lido withdrawal.
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);

        // It should store multiple withdrawal request IDs.
        uint256[] memory storedRequestIds = adapter.getLidoWithdrawalRequestIds(vaultIds.vaultWithAdapter);
        assertEq(storedRequestIds.length, 2, "requestIds length");
        assertEq(storedRequestIds[0], 1, "requestIds[0]");
        assertEq(storedRequestIds[1], 2, "requestIds[1]");
    }
}
