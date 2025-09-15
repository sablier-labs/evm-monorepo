// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Core as DeployProxyUtils, Options } from "@openzeppelin/foundry-upgrades/src/internal/Core.sol";
import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @dev Utility functions for validating and deploying proxy contract and its implementation.
abstract contract ProxyHelpers is BaseScript {
    /// @dev Returns the implementation address of a proxy contract by reading its implementation storage slot.
    function _getImplementation(address proxy) internal view returns (address) {
        return DeployProxyUtils.getImplementationAddress(proxy);
    }

    /// @dev Initializes the proxy contract by populating its initial states.
    function _populateInitialStates(address proxy) internal {
        SablierComptroller comptrollerProxy = SablierComptroller(payable(proxy));

        comptrollerProxy.initialize({
            initialAdmin: getAdmin(),
            initialAirdropMinFeeUSD: getInitialMinFeeUSD(),
            initialLockupMinFeeUSD: getInitialMinFeeUSD(),
            initialFlowMinFeeUSD: getInitialMinFeeUSD(),
            initialOracle: getChainlinkOracle()
        });
    }

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
        DeployProxyUtils.validateImplementation({ contractName: "SablierComptroller.sol:SablierComptroller", opts: opts });
    }

    /// @dev Verifies the initial states of the proxy contract.
    function _verifyInitialStates(address proxy) internal view {
        ISablierComptroller comptrollerProxy = ISablierComptroller(payable(proxy));
        assert(comptrollerProxy.admin() == getAdmin());
        assert(comptrollerProxy.getMinFeeUSD(ISablierComptroller.Protocol.Airdrops) == getInitialMinFeeUSD());
        assert(comptrollerProxy.getMinFeeUSD(ISablierComptroller.Protocol.Lockup) == getInitialMinFeeUSD());
        assert(comptrollerProxy.getMinFeeUSD(ISablierComptroller.Protocol.Flow) == getInitialMinFeeUSD());
        assert(address(comptrollerProxy.oracle()) == getChainlinkOracle());
    }
}
