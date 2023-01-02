// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { ComptrollerTest } from "../ComptrollerTest.t.sol";

contract SetProtocolFee__ComptrollerTest is ComptrollerTest {
    /// @dev it should revert.
    function testCannotSetProtocolFee__CallerNotOwner(address eve) external {
        vm.assume(eve != users.owner);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable__CallerNotOwner.selector, users.owner, eve));
        comptroller.setProtocolFee(address(dai), MAX_FEE);
    }

    modifier CallerOwner() {
        // Make the owner the caller in the rest of this test suite.
        changePrank(users.owner);
        _;
    }

    /// @dev it should re-set the protocol fee.
    function testSetProtocolFee__SameFee() external CallerOwner {
        UD60x18 newProtocolFee = ud(0);
        comptroller.setProtocolFee(address(dai), newProtocolFee);

        UD60x18 actualProtocolFee = comptroller.getProtocolFee(address(dai));
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee);
    }

    /// @dev it should set the new protocol fee
    function testSetProtocolFee__DifferentFee(UD60x18 newProtocolFee) external CallerOwner {
        newProtocolFee = bound(newProtocolFee, 1, MAX_FEE);
        comptroller.setProtocolFee(address(dai), newProtocolFee);

        UD60x18 actualProtocolFee = comptroller.getProtocolFee(address(dai));
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee);
    }
}
