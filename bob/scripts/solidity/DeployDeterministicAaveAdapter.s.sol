// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22 <0.9.0;

import { BaseScript } from "@sablier/evm-utils/src/tests/BaseScript.sol";

import { SablierAaveAdapter } from "../../src/SablierAaveAdapter.sol";
import { AaveAdapterUtils } from "./AaveAdapterUtils.s.sol";

/// @notice Deploys {SablierAaveAdapter} at a deterministic address across chains.
/// @dev Reverts if the contract has already been deployed.
contract DeployDeterministicAaveAdapter is BaseScript, AaveAdapterUtils {
    function run(address sablierBob) public broadcast returns (SablierAaveAdapter aaveAdapter) {
        aaveAdapter = new SablierAaveAdapter{ salt: SALT }({
            aavePoolAddressesProvider: getAavePoolAddressesProvider(),
            initialComptroller: getComptroller(),
            initialYieldFee: INITIAL_YIELD_FEE,
            sablierBob: sablierBob
        });
    }
}
