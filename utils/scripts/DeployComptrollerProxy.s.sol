// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Options, Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import { SablierComptroller } from "../src/SablierComptroller.sol";
import { BaseScript } from "../src/tests/BaseScript.sol";

/// @notice Deploys a new proxy and the Sablier Comptroller.
/// @dev The deployed Sablier Comptroller is set as the implementation of the proxy. See
/// https://docs.openzeppelin.com/upgrades-plugins/foundry-upgrades#usage for more details.
contract DeployComptrollerProxy is BaseScript {
    function run() public broadcast returns (address proxy, address implementation) {
        // Declare the constructor parameters of the implementation contract.
        Options memory opts;
        opts.constructorData = abi.encode(getAdmin());

        // Disable the constructor check for the implementation contract. See
        // https://docs.openzeppelin.com/upgrades-plugins/faq#how-can-i-disable-checks.
        opts.unsafeAllow = "constructor";

        // Declare the initializer data for the proxy.
        bytes memory initializerData = abi.encodeCall(
            SablierComptroller.initialize,
            (getAdmin(), getInitialMinFeeUSD(), getInitialMinFeeUSD(), getInitialMinFeeUSD(), getChainlinkOracle())
        );

        // Perform the following steps:
        // 1. Deploys the proxy.
        // 2. Deploys the Comptroller.
        // 3. Sets the implementation of the proxy to the address of the deployed Comptroller.
        // 4. Initializes the state variables in the proxy contract.
        proxy = Upgrades.deployUUPSProxy({
            contractName: "SablierComptroller.sol:SablierComptroller",
            initializerData: initializerData,
            opts: opts
        });

        implementation = Upgrades.getImplementationAddress(proxy);
    }
}
