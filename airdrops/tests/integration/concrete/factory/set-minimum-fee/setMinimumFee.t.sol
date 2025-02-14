// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../Integration.t.sol";

contract SetMinimumFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        uint256 minimumFee = defaults.MINIMUM_FEE();
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.setMinimumFee({ minimumFee: minimumFee });
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });

        // It should emit a {SetMinimumFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.SetMinimumFee({ admin: users.admin, minimumFee: defaults.MINIMUM_FEE() });

        merkleFactory.setMinimumFee({ minimumFee: defaults.MINIMUM_FEE() });

        // It should set the minimum fee.
        assertEq(merkleFactory.minimumFee(), defaults.MINIMUM_FEE(), "minimum fee");
    }
}
