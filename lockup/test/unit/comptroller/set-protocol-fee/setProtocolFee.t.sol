// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IAdminable } from "@prb/contracts/access/IAdminable.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Comptroller_Unit_Test } from "../Comptroller.t.sol";

contract SetProtocolFee_Unit_Test is Comptroller_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin(address eve) external {
        vm.assume(eve != users.admin);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IAdminable.Adminable_CallerNotAdmin.selector, users.admin, eve));
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: DEFAULT_MAX_FEE });
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank(users.admin);
        _;
    }

    /// @dev it should re-set the protocol fee.
    function test_SetProtocolFee_SameFee() external callerAdmin {
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = ZERO;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }

    modifier newFee() {
        _;
    }

    /// @dev it should set the new protocol fee and emit a {SetProtocolFee} event.
    function testFuzz_SetProtocolFee(UD60x18 newProtocolFee) external callerAdmin newFee {
        newProtocolFee = bound(newProtocolFee, 1, DEFAULT_MAX_FEE);

        // Expect a {SetProtocolFee} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.SetProtocolFee({
            admin: users.admin,
            asset: DEFAULT_ASSET,
            oldProtocolFee: ZERO,
            newProtocolFee: newProtocolFee
        });

        // Set the new protocol fee.
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: newProtocolFee });

        // Assert that the protocol fee was updated.
        UD60x18 actualProtocolFee = comptroller.getProtocolFee(DEFAULT_ASSET);
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee, "protocolFee");
    }
}
