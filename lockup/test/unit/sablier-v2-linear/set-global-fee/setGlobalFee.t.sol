// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";
import { UD60x18, unwrap, wrap } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract SetGlobalFee__Test is SablierV2LinearTest {
    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Make the owner the caller in this test suite.
        changePrank(users.owner);
    }

    /// @dev it should revert.
    function testCannotSetGlobalFee__CallerNotOwner() external {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable__CallerNotOwner.selector, users.owner, users.eve));
        sablierV2Linear.setGlobalFee(address(dai), MAX_GLOBAL_FEE);
    }

    modifier CallerOwner() {
        _;
    }

    /// @dev it should revert.
    function testCannotSetGlobalFee__NewGlobalFeeGreaterThanMaxPermitted() external CallerOwner {
        UD60x18 newGlobalFee = MAX_GLOBAL_FEE.add(wrap(1));
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__NewGlobalFeeGreaterThanMaxPermitted.selector,
                newGlobalFee,
                MAX_GLOBAL_FEE
            )
        );
        sablierV2Linear.setGlobalFee(address(dai), newGlobalFee);
    }

    modifier LessThanOrEqualToMaxPermitted() {
        _;
    }

    /// @dev it should set the new global fee.
    function testSetGlobalFee__SameFee() external CallerOwner LessThanOrEqualToMaxPermitted {
        UD60x18 newGlobalFee = wrap(0);
        sablierV2Linear.setGlobalFee(address(dai), newGlobalFee);

        UD60x18 actualGlobalFee = sablierV2Linear.getGlobalFee(address(dai));
        UD60x18 expectedGlobalFee = newGlobalFee;
        assertEq(actualGlobalFee, expectedGlobalFee);
    }

    /// @dev it should set the new global fee.
    function testSetGlobalFee__DifferentFee(UD60x18 newGlobalFee) external CallerOwner LessThanOrEqualToMaxPermitted {
        newGlobalFee = bound(newGlobalFee, 1, MAX_GLOBAL_FEE);
        sablierV2Linear.setGlobalFee(address(dai), newGlobalFee);

        UD60x18 actualGlobalFee = sablierV2Linear.getGlobalFee(address(dai));
        UD60x18 expectedGlobalFee = newGlobalFee;
        assertEq(actualGlobalFee, expectedGlobalFee);
    }
}
