// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { SablierComptroller } from "src/SablierComptroller.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @notice Deploys the Sablier Comptroller implementation.
/// @dev Use this when the proxy already exists and the upgrade will be proposed through a multisig.
contract DeployComptrollerImpl is BaseScript {
    function run() public broadcast returns (address implementation) {
        // Deploy implementation contract with the chain-specific admin.
        implementation = address(new SablierComptroller({ initialAdmin: getAdmin() }));
    }
}
