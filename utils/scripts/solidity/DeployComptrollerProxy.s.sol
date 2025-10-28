// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";
import { ProxyHelpers } from "./ProxyHelpers.sol";

/// @notice Deploys a new proxy and the Sablier Comptroller.
/// @dev The deployed Sablier Comptroller is set as the implementation of the proxy.
contract DeployComptrollerProxy is ProxyHelpers {
    function run() public broadcast returns (address proxy, address implementation) {
        // Run upgrade safety checks.
        _runUpgradeSafetyChecks();

        // Deploy implementation contract with default admin as its initial admin.
        address impl = address(new SablierComptroller({ initialAdmin: DEFAULT_SABLIER_ADMIN }));

        // Deploy proxy without initialization.
        proxy = address(new ERC1967Proxy({ implementation: impl, _data: "" }));

        // Initialize the proxy by populating its initial states.
        _populateInitialStates(proxy);

        // Get implementation address by reading the implementation storage slot of the proxy.
        implementation = _getImplementation(proxy);

        // Verify the initial states of the proxy contract.
        _verifyInitialStates(proxy);
    }
}
