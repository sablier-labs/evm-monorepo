// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { NonDeterministicComptrollerDeployer } from "./AtomicComptrollerDeployer.sol";
import { ProxyHelpers } from "./ProxyHelpers.sol";

/// @notice Deploys a new Comptroller implementation and initialized proxy in one transaction.
contract DeployComptrollerProxy is ProxyHelpers {
    function run() public broadcast returns (address proxy, address implementation) {
        // Run upgrade safety checks.
        _runUpgradeSafetyChecks();

        NonDeterministicComptrollerDeployer deployer = new NonDeterministicComptrollerDeployer({
            initialAdmin: getAdmin(),
            initialMinFeeUSD: getInitialMinFeeUSD(),
            initialOracle: getChainlinkOracle()
        });
        proxy = deployer.PROXY();
        implementation = deployer.IMPLEMENTATION();
    }
}
