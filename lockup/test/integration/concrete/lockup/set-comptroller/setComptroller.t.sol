// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { Lockup_Integration_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract SetComptroller_Integration_Concrete_Test is Integration_Test, Lockup_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Lockup_Integration_Shared_Test) { }

    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        base.setComptroller(ISablierV2Comptroller(users.eve));
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_SetComptroller_SameComptroller() external whenCallerAdmin {
        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(base) });
        emit SetComptroller(users.admin, comptroller, comptroller);

        // Re-set the comptroller.
        base.setComptroller(comptroller);

        // Assert that the comptroller has not been changed.
        address actualComptroller = address(base.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");
    }

    function test_SetComptroller_NewComptroller() external whenCallerAdmin {
        // Deploy the new comptroller.
        ISablierV2Comptroller newComptroller = new SablierV2Comptroller({ initialAdmin: users.admin });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(base) });
        emit SetComptroller(users.admin, comptroller, newComptroller);

        // Set the new comptroller.
        base.setComptroller(newComptroller);

        // Assert that the new comptroller has been set.
        address actualComptroller = address(base.comptroller());
        address expectedComptroller = address(newComptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");
    }
}
