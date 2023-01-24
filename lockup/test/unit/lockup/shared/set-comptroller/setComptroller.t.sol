// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract SetComptroller_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ who: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Adminable_CallerNotAdmin.selector, users.admin, users.eve)
        );
        config.setComptroller(ISablierV2Comptroller(users.eve));
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank({ who: users.admin });
        _;
    }

    /// @dev it should re-set the comptroller and emit a {SetComptroller} event.
    function test_SetComptroller_SameComptroller() external callerAdmin {
        // Expect a {SetComptroller} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit Events.SetComptroller(users.admin, comptroller, comptroller);

        // Re-set the comptroller.
        config.setComptroller(comptroller);

        // Assert that the comptroller did not change.
        address actualComptroller = address(config.comptroller());
        address expectedComptroller = address(comptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");
    }

    /// @dev it should set the new comptroller and emit a {SetComptroller} event.
    function test_SetComptroller_NewComptroller() external callerAdmin {
        // Deploy the new comptroller.
        ISablierV2Comptroller newComptroller = new SablierV2Comptroller({ initialAdmin: users.admin });

        // Expect a {SetComptroller} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: false, checkTopic3: false, checkData: true });
        emit Events.SetComptroller(users.admin, comptroller, newComptroller);

        // Set the new comptroller.
        config.setComptroller(newComptroller);

        // Assert that the new comptroller was set.
        address actualComptroller = address(config.comptroller());
        address expectedComptroller = address(newComptroller);
        assertEq(actualComptroller, expectedComptroller, "comptroller");
    }
}
