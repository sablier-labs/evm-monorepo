// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";
import { UD60x18, unwrap, wrap } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2ComptrollerTest } from "../SablierV2Comptroller.t.sol";

contract SetProtocolFee__Test is SablierV2ComptrollerTest {
    /// @dev it should revert.
    function testCannotSetProtocolFee__CallerNotOwner() external {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable__CallerNotOwner.selector, users.owner, users.eve));
        sablierV2Comptroller.setProtocolFee(address(dai), MAX_FEE);
    }

    modifier CallerOwner() {
        // Make the owner the caller in the rest of this test suite.
        changePrank(users.owner);
        _;
    }

    /// @dev it should set the new global fee.
    function testSetProtocolFee__SameFee() external CallerOwner {
        UD60x18 newProtocolFee = wrap(0);
        sablierV2Comptroller.setProtocolFee(address(dai), newProtocolFee);

        UD60x18 actualProtocolFee = sablierV2Comptroller.getProtocolFee(address(dai));
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee);
    }

    /// @dev it should set the new global fee.
    function testSetProtocolFee__DifferentFee(UD60x18 newProtocolFee) external CallerOwner {
        newProtocolFee = bound(newProtocolFee, 1, MAX_FEE);
        sablierV2Comptroller.setProtocolFee(address(dai), newProtocolFee);

        UD60x18 actualProtocolFee = sablierV2Comptroller.getProtocolFee(address(dai));
        UD60x18 expectedProtocolFee = newProtocolFee;
        assertEq(actualProtocolFee, expectedProtocolFee);
    }
}
