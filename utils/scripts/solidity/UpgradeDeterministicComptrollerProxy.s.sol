// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";
import { BaseScript } from "src/tests/BaseScript.sol";

/// @notice Deterministically deploys Comptroller v1.1 and upgrades an EOA-administered canonical proxy to it.
contract UpgradeDeterministicComptrollerProxy is BaseScript {
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    string internal constant DEPLOYMENT_VERSION = "2.0.0";

    function run() public broadcast returns (address implementation) {
        bytes32 implSalt = bytes32(abi.encodePacked(string.concat("Version ", getVersion())));
        bytes memory creationCode = bytes.concat(type(SablierComptroller).creationCode, abi.encode(getAdmin()));
        implementation = address(
            uint160(
                uint256(keccak256(abi.encodePacked(bytes1(0xff), CREATE2_FACTORY, implSalt, keccak256(creationCode))))
            )
        );
        if (implementation.code.length == 0) {
            address deployed = address(new SablierComptroller{ salt: implSalt }({ initialAdmin: getAdmin() }));
            vm.assertEq(deployed, implementation, "implementation: unexpected address");
        }

        address proxy = getComptroller();
        vm.assertGt(proxy.code.length, 0, "proxy: not deployed");
        address currentImplementation = address(uint160(uint256(vm.load(proxy, IMPLEMENTATION_SLOT))));
        if (currentImplementation != implementation) {
            UUPSUpgradeable(proxy).upgradeToAndCall(implementation, "");
        }

        SablierComptroller comptroller = SablierComptroller(payable(proxy));
        if (comptroller.admin() != getAdmin()) {
            vm.assertEq(comptroller.admin(), broadcaster, "proxy: unexpected bootstrap admin");
            comptroller.transferAdmin(getAdmin());
        }
        vm.assertEq(comptroller.admin(), getAdmin(), "proxy: admin");
        vm.assertEq(comptroller.oracle(), getChainlinkOracle(), "proxy: oracle");
    }

    function getVersion() public pure override returns (string memory) {
        return DEPLOYMENT_VERSION;
    }
}
