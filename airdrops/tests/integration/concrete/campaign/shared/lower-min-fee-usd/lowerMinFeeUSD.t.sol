// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract LowerMinFeeUSD_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotFactoryAdmin() external {
        resetPrank({ msgSender: users.campaignCreator });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CallerNotFactoryAdmin.selector, users.admin, users.campaignCreator
            )
        );
        merkleBase.lowerMinFeeUSD(MIN_FEE_USD - 1);
    }

    function test_RevertWhen_NewFeeNotLower() external whenCallerFactoryAdmin {
        uint256 newMinFeeUSD = MIN_FEE_USD + 1;
        resetPrank(users.admin);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_NewMinFeeUSDNotLower.selector, MIN_FEE_USD, newMinFeeUSD)
        );
        merkleBase.lowerMinFeeUSD(newMinFeeUSD);
    }

    function test_WhenNewFeeNotZero() external whenCallerFactoryAdmin whenNewFeeLower {
        uint256 newMinFeeUSD = MIN_FEE_USD - 1;
        resetPrank(users.admin);

        // It should emit a {LowerMinFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.LowerMinFeeUSD(users.admin, newMinFeeUSD, MIN_FEE_USD);

        merkleBase.lowerMinFeeUSD(newMinFeeUSD);

        // It should set the min USD fee to the new lower value.
        assertEq(merkleBase.minFeeUSD(), newMinFeeUSD);
    }

    function test_WhenNewFeeZero() external whenCallerFactoryAdmin whenNewFeeLower {
        resetPrank(users.admin);

        // It should emit a {LowerMinFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.LowerMinFeeUSD(users.admin, 0, MIN_FEE_USD);

        merkleBase.lowerMinFeeUSD(0);

        // It should set the new min USD fee to zero.
        assertEq(merkleBase.minFeeUSD(), 0);
    }
}
