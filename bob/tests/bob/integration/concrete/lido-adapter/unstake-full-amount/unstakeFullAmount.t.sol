// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ICurveStETHPool } from "src/interfaces/external/ICurveStETHPool.sol";
import { ILidoWithdrawalQueue } from "src/interfaces/external/ILidoWithdrawalQueue.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IWstETH } from "src/interfaces/external/IWstETH.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract UnstakeFullAmount_Integration_Concrete_Test is Integration_Test {
    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.unstakeFullAmount(vaultIds.vaultWithAdapter);
    }

    function test_RevertWhen_ETHReceivedNotExceedETHExpected() external whenCallerBob givenCurveWithdrawalRequested {
        // Update Curve mock such that amount exchanged is less than the output received by the `get_dy` function.
        curvePool.setDiff(1e18);

        uint256 expectedMinEthOut = calculateMinEthOut(DEPOSIT_AMOUNT, SLIPPAGE_TOLERANCE);
        uint256 expectedEthOutFromExchange = DEPOSIT_AMOUNT - 1e18;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLidoAdapter_SlippageExceeded.selector, expectedMinEthOut, expectedEthOutFromExchange
            )
        );
        adapter.unstakeFullAmount(vaultIds.vaultWithAdapter);
    }

    function test_WhenETHReceivedExceedsETHExpected() external whenCallerBob givenCurveWithdrawalRequested {
        // Simulate yield generation at settlement by lowering the exchange rate.
        UD60x18 newExchangeRate = UD60x18.wrap(0.8e18);
        wstEth.setExchangeRate(newExchangeRate);

        uint128 expectedEthReceived = expectedWethFromWstEth(WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, newExchangeRate);
        uint128 expectedMinEthOut = calculateMinEthOut(expectedEthReceived, SLIPPAGE_TOLERANCE);

        // It should unwrap wstETH to stETH.
        vm.expectCall({
            callee: address(wstEth),
            data: abi.encodeCall(IWstETH.unwrap, (WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT))
        });

        // It should swap stETH for ETH via Curve.
        vm.expectCall({
            callee: address(curvePool),
            data: abi.encodeCall(
                ICurveStETHPool.exchange, (int128(1), int128(0), expectedEthReceived, expectedMinEthOut)
            )
        });

        // It should wrap ETH into WETH.
        vm.expectCall({
            callee: address(weth),
            msgValue: expectedEthReceived,
            data: abi.encodeCall(IWETH9.deposit, ())
        });

        // It should transfer WETH to Bob.
        expectCallToTransfer(weth, address(bob), expectedEthReceived);

        // It should emit an {UnstakeFullAmount} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.UnstakeFullAmount({
            vaultId: vaultIds.vaultWithAdapter,
            totalStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            amountReceivedFromUnstaking: expectedEthReceived
        });

        (uint128 wrappedTokenBalance, uint128 amountReceivedFromUnstaking) =
            adapter.unstakeFullAmount(vaultIds.vaultWithAdapter);

        // It should return the wrapped token balance.
        assertEq(wrappedTokenBalance, WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, "wrappedTokenBalance");

        // It should return the amount received from unstaking.
        assertEq(amountReceivedFromUnstaking, expectedEthReceived, "amountReceivedFromUnstaking");

        // It should update the WETH amount received after unstaking.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter),
            expectedEthReceived,
            "wethReceivedAfterUnstaking"
        );
    }

    function test_GivenLidoWithdrawalRequested() external whenCallerBob {
        // First, request a Lido withdrawal.
        setMsgSender(address(comptroller));
        adapter.requestLidoWithdrawal(vaultIds.vaultWithAdapter);

        vm.expectCall({
            callee: address(lidoWithdrawalQueue),
            data: abi.encodeCall(ILidoWithdrawalQueue.getLastCheckpointIndex, ())
        });

        // It should wrap ETH into WETH.
        vm.expectCall({ callee: address(weth), msgValue: DEPOSIT_AMOUNT, data: abi.encodeCall(IWETH9.deposit, ()) });

        // It should transfer WETH to Bob.
        expectCallToTransfer(weth, address(bob), DEPOSIT_AMOUNT);

        // It should emit an {UnstakeFullAmount} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.UnstakeFullAmount({
            vaultId: vaultIds.vaultWithAdapter,
            wrappedStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT,
            withdrawnAmount: DEPOSIT_AMOUNT
        });

        setMsgSender(address(bob));
        (uint128 wrappedTokenBalance, uint128 amountReceivedFromUnstaking) =
            adapter.unstakeFullAmount(vaultIds.vaultWithAdapter);

        // It should return the wrapped token balance.
        assertEq(wrappedTokenBalance, WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT, "wrappedTokenBalance");

        // It should return the amount received from unstaking.
        assertEq(amountReceivedFromUnstaking, DEPOSIT_AMOUNT, "amountReceivedFromUnstaking");

        // It should update WETH amount received after unstaking.
        assertEq(
            adapter.getWethReceivedAfterUnstaking(vaultIds.vaultWithAdapter),
            DEPOSIT_AMOUNT,
            "wethReceivedAfterUnstaking"
        );
    }
}
