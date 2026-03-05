// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";
import { ChainId } from "@sablier/evm-utils/src/tests/ChainId.sol";

import { SablierBob } from "../../src/SablierBob.sol";
import { SablierLidoAdapter } from "../../src/SablierLidoAdapter.sol";
import { LidoAdapterUtils } from "./LidoAdapterUtils.s.sol";

/// @notice Deploys {SablierBob} at a deterministic address across chains. On Ethereum mainnet and Sepolia, it also
/// deploys {SablierLidoAdapter}.
/// @dev Reverts if the contracts have already been deployed.
contract DeployDeterministicBob is BaseScript, LidoAdapterUtils {
    function run() public broadcast returns (SablierBob bob, SablierLidoAdapter lidoAdapter) {
        bob = new SablierBob{ salt: SALT }(getComptroller());

        // Deploy Lido adapter if on Ethereum mainnet or Sepolia.
        if (block.chainid == ChainId.ETHEREUM || block.chainid == ChainId.SEPOLIA) {
            lidoAdapter = _deployLidoAdapter(bob);
        }
    }

    function _deployLidoAdapter(SablierBob bob) private returns (SablierLidoAdapter lidoAdapter) {
        lidoAdapter = new SablierLidoAdapter{ salt: SALT }({
            initialComptroller: getComptroller(),
            sablierBob: address(bob),
            curvePool: getCurvePool(),
            lidoWithdrawalQueue: getLidoWithdrawalQueue(),
            stETH: getStETH(),
            stETH_ETH_Oracle: getStETH_ETHOracle(),
            wETH: getWETH(),
            wstETH: getWSTETH(),
            initialSlippageTolerance: INITIAL_SLIPPAGE_TOLERANCE,
            initialYieldFee: INITIAL_YIELD_FEE
        });
    }
}
