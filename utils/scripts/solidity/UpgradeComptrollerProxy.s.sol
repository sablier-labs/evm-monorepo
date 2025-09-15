// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Options, Upgrades } from "@openzeppelin/foundry-upgrades/src/Upgrades.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @notice Deploys a new Sablier Comptroller.
/// @dev The deployed Sablier Comptroller is set as the implementation of the existing proxy.
contract UpgradeComptrollerProxy is BaseScript {
    // TODO: Replace with the actual proxy address.
    address public constant COMPTROLLER_PROXY = 0x0000000000000000000000000000000000000000;

    function run() public broadcast returns (address implementation) {
        // Declare the constructor parameters of the implementation contract.
        Options memory opts;
        opts.constructorData = abi.encode(getAdmin());

        // Disable the constructor check for the implementation contract.
        // See https://docs.openzeppelin.com/upgrades-plugins/faq#how-can-i-disable-checks
        opts.unsafeAllow = "constructor";

        // Perform the following steps:
        // 1. Deploys the Comptroller.
        // 2. Sets the implementation of the proxy to the address of the deployed Comptroller.
        Upgrades.upgradeProxy({
            proxy: COMPTROLLER_PROXY,
            contractName: "SablierComptroller.sol:SablierComptroller",
            data: "",
            opts: opts
        });

        implementation = Upgrades.getImplementationAddress(COMPTROLLER_PROXY);
    }
}
