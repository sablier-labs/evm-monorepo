// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";
import { ProxyHelpers } from "./ProxyHelpers.sol";

/// @notice Deploys a new proxy and the Sablier Comptroller using CREATE2.
/// @dev The deployed Sablier Comptroller is set as the implementation of the proxy.
contract DeployDeterministicComptrollerProxy is ProxyHelpers {
    function run() public broadcast returns (address proxy, address implementation) {
        // Run upgrade safety checks.
        _runUpgradeSafetyChecks();

        // Generate CREATE2 salt independent of chain id.
        bytes32 salt = bytes32(abi.encodePacked(string.concat("Version ", getVersion())));

        // Deploy implementation contract with default admin as its initial admin. The default EOA admin is used across
        // all chains so that we can have same the address for the implementation contract.
        address impl = address(new SablierComptroller{ salt: salt }({ initialAdmin: DEFAULT_SABLIER_ADMIN }));

        // Deploy proxy without initialization.
        proxy = address(new ERC1967Proxy{ salt: salt }({ implementation: impl, _data: "" }));

        // Initialize the proxy by populating its initial states.
        _populateInitialStates(proxy);

        // Get implementation address by reading the implementation storage slot of the proxy.
        implementation = _getImplementation(proxy);

        // Verify the initial states of the proxy contract.
        _verifyInitialStates(proxy);
    }
}
