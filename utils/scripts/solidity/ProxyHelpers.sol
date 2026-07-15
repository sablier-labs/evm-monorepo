// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Core as DeployProxyUtils, Options } from "@openzeppelin/foundry-upgrades/src/internal/Core.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @dev Utility for running Comptroller upgrade safety checks.
abstract contract ProxyHelpers is BaseScript {
    /// @dev Runs upgrade safety checks on the Comptroller contract. To see full list of the checks performed, visit
    /// https://docs.openzeppelin.com/upgrades-plugins/faq#how-can-i-disable-checks.
    function _runUpgradeSafetyChecks() internal {
        // Set `FOUNDRY_OUT` since this value is read by the safety checks function.
        string memory profile = vm.envOr({ name: "FOUNDRY_PROFILE", defaultValue: string("default") });
        if (Strings.equal(profile, "optimized")) {
            vm.setEnv("FOUNDRY_OUT", "out-optimized");
        }

        // Disable the constructor check.
        Options memory opts;
        opts.unsafeAllow = "constructor";

        // Run validation checks.
        DeployProxyUtils.validateImplementation({
            contractName: "SablierComptroller.sol:SablierComptroller",
            opts: opts
        });
    }
}
