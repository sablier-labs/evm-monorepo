// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { SablierComptroller } from "src/SablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Base_Test } from "tests/Base.t.sol";

contract UpgradeToAndCall_Comptroller_Concrete_Test is Base_Test {
    UUPSUpgradeable internal comptrollerCastedToUUPS;

    address internal newImplementation;

    function setUp() public override {
        Base_Test.setUp();

        comptrollerCastedToUUPS = UUPSUpgradeable(address(comptroller));
    }

    function test_RevertWhen_CallerNotAdmin() external {
        setMsgSender(users.eve);

        newImplementation = vm.randomAddress();

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, admin, users.eve));
        comptrollerCastedToUUPS.upgradeToAndCall(newImplementation, "");
    }

    function test_RevertWhen_NewImplementationNotCompatible() external whenCallerAdmin {
        newImplementation = vm.randomAddress();

        // It should revert.
        vm.expectRevert();
        comptrollerCastedToUUPS.upgradeToAndCall(newImplementation, "");
    }

    function test_WhenNewImplementationCompatible() external whenCallerAdmin {
        // Deploy a new implementation that supports {IERC1822Proxiable} interface.
        newImplementation = address(new SablierComptroller(admin));

        // Upgrade to the new implementation.
        comptrollerCastedToUUPS.upgradeToAndCall(newImplementation, "");

        // It should set the new implementation.
        address actualComptrollerImpl = getComptrollerImplAddress();
        address expectedComptrollerImpl = newImplementation;
        assertEq(actualComptrollerImpl, expectedComptrollerImpl, "implementation");
    }
}
