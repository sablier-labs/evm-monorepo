// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IStETH } from "src/interfaces/external/IStETH.sol";
import { IWETH9 } from "src/interfaces/external/IWETH9.sol";
import { IWstETH } from "src/interfaces/external/IWstETH.sol";
import { ISablierBobAdapter } from "src/interfaces/ISablierBobAdapter.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract Stake_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Since this test is from Bob's perspective, we need to transfer WETH to the adapter before calling `stake`.
        weth.transfer(address(adapter), DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_CallerNotBob() external {
        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLidoAdapter_OnlySablierBob.selector, users.depositor, address(bob))
        );
        adapter.stake(vaultIds.vaultWithAdapter, users.newDepositor, DEPOSIT_AMOUNT);
    }

    function test_WhenCallerBob() external {
        // It should unwrap WETH into ETH.
        vm.expectCall({ callee: address(weth), data: abi.encodeCall(IWETH9.withdraw, (DEPOSIT_AMOUNT)) });

        // It should stake ETH to get stETH.
        vm.expectCall({
            callee: address(steth),
            msgValue: DEPOSIT_AMOUNT,
            data: abi.encodeCall(IStETH.submit, (address(comptroller)))
        });

        // It should wrap stETH into wstETH.
        vm.expectCall({ callee: address(wstEth), data: abi.encodeCall(IWstETH.wrap, (DEPOSIT_AMOUNT)) });

        // It should emit a {Stake} event.
        vm.expectEmit({ emitter: address(adapter) });
        emit ISablierBobAdapter.Stake({
            vaultId: vaultIds.vaultWithAdapter,
            user: users.newDepositor,
            depositAmount: DEPOSIT_AMOUNT,
            wrappedStakedAmount: WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT
        });

        // Change caller to Bob.
        setMsgSender(address(bob));
        adapter.stake(vaultIds.vaultWithAdapter, users.newDepositor, DEPOSIT_AMOUNT);

        // It should update vault total wstETH balance.
        uint128 actualVaultTotalWstETH = adapter.getTotalYieldBearingTokenBalance(vaultIds.vaultWithAdapter);
        uint128 expectedVaultTotalWstETH = 2 * WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualVaultTotalWstETH, expectedVaultTotalWstETH, "vaultTotalWstETH");

        // It should update user wstETH balance.
        uint128 actualUserWstETH = adapter.getYieldBearingTokenBalanceFor(vaultIds.vaultWithAdapter, users.newDepositor);
        uint128 expectedUserWstETH = WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT;
        assertEq(actualUserWstETH, expectedUserWstETH, "userWstETH");
    }
}
