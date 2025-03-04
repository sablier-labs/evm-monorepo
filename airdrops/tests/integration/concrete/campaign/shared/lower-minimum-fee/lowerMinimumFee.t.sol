// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract LowerMinimumFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotFactoryAdmin() external {
        resetPrank({ msgSender: users.campaignOwner });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CallerNotFactoryAdmin.selector, users.admin, users.campaignOwner
            )
        );
        merkleBase.lowerMinimumFee(MINIMUM_FEE - 1);
    }

    function test_RevertWhen_NewFeeNotLower() external whenCallerFactoryAdmin {
        uint256 newFee = MINIMUM_FEE + 1;
        resetPrank(users.admin);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_NewFeeHigher.selector, MINIMUM_FEE, newFee));
        merkleBase.lowerMinimumFee(newFee);
    }

    function test_WhenNewFeeNotZero() external whenCallerFactoryAdmin whenNewFeeLower {
        uint256 newFee = MINIMUM_FEE - 1;
        resetPrank(users.admin);

        // It should emit a {LowerMinimumFee} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.LowerMinimumFee(users.admin, newFee, MINIMUM_FEE);

        merkleBase.lowerMinimumFee(newFee);

        // It should lower the minimum fee to the new value.
        assertEq(merkleBase.minimumFee(), newFee);
    }

    function test_WhenNewFeeZero() external whenCallerFactoryAdmin whenNewFeeLower {
        resetPrank(users.admin);

        // It should emit a {LowerMinimumFee} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.LowerMinimumFee(users.admin, 0, MINIMUM_FEE);

        merkleBase.lowerMinimumFee(0);

        // It should lower the minimum fee to zero.
        assertEq(merkleBase.minimumFee(), 0);
    }
}
