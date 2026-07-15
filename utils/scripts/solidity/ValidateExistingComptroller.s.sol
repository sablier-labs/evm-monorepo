// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @notice Validates the configured existing Comptroller proxy before deploying dependent protocols.
/// @dev This script never deploys, initializes, or upgrades a Comptroller.
contract ValidateExistingComptroller is BaseScript {
    error ImplementationNotDeployed(address implementation);
    error ProxyNotDeployed(address proxy);
    error UnexpectedAdmin(address actual, address expected);
    error UnexpectedInterface(bytes4 actual, bytes4 expected);
    error UnexpectedOracle(address actual, address expected);
    error UnsupportedInterface(bytes4 interfaceId);

    bytes4 private constant EXPECTED_INTERFACE_ID = ISablierComptroller.calculateMinFeeWeiFor.selector
        ^ ISablierComptroller.convertUSDFeeToWei.selector ^ ISablierComptroller.execute.selector
        ^ ISablierComptroller.getMinFeeUSDFor.selector;
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function run() public view returns (address proxy, address implementation) {
        proxy = getComptroller();
        if (proxy.code.length == 0) revert ProxyNotDeployed(proxy);

        implementation = address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
        if (implementation.code.length == 0) revert ImplementationNotDeployed(implementation);

        ISablierComptroller comptroller = ISablierComptroller(payable(proxy));
        address expectedAdmin = getAdmin();
        address actualAdmin = comptroller.admin();
        if (actualAdmin != expectedAdmin) revert UnexpectedAdmin({ actual: actualAdmin, expected: expectedAdmin });

        address expectedOracle = getChainlinkOracle();
        address actualOracle = address(comptroller.oracle());
        if (actualOracle != expectedOracle) {
            revert UnexpectedOracle({ actual: actualOracle, expected: expectedOracle });
        }

        bytes4 actualInterfaceId = comptroller.MINIMAL_INTERFACE_ID();
        if (actualInterfaceId != EXPECTED_INTERFACE_ID) {
            revert UnexpectedInterface({ actual: actualInterfaceId, expected: EXPECTED_INTERFACE_ID });
        }
        if (!comptroller.supportsInterface(EXPECTED_INTERFACE_ID)) {
            revert UnsupportedInterface(EXPECTED_INTERFACE_ID);
        }
    }
}
