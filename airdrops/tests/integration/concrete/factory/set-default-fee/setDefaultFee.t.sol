// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

contract SetDefaultFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        uint256 fee = defaults.DEFAULT_FEE();
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.setDefaultFee({ defaultFee: fee });
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });

        // It should emit a {SetDefaultFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.SetDefaultFee({ admin: users.admin, defaultFee: defaults.DEFAULT_FEE() });

        merkleFactory.setDefaultFee({ defaultFee: defaults.DEFAULT_FEE() });

        // It should set the default fee.
        assertEq(merkleFactory.defaultFee(), defaults.DEFAULT_FEE(), "default fee");
    }
}
