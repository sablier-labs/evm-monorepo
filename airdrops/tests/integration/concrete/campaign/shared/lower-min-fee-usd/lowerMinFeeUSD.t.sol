// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleBase } from "src/interfaces/ISablierMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract LowerMinFeeUSD_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotComptroller() external {
        setMsgSender(users.eve);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_CallerNotComptroller.selector, address(comptroller), users.eve
            )
        );
        merkleBase.lowerMinFeeUSD(AIRDROP_MIN_FEE_USD - 1);
    }

    function test_RevertWhen_NewFeeNotLower() external whenCallerComptroller {
        uint256 newMinFeeUSD = AIRDROP_MIN_FEE_USD + 1;

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_NewMinFeeUSDNotLower.selector, AIRDROP_MIN_FEE_USD, newMinFeeUSD
            )
        );
        merkleBase.lowerMinFeeUSD(newMinFeeUSD);
    }

    function test_WhenNewFeeNotZero() external whenCallerComptroller whenNewFeeLower {
        uint256 newMinFeeUSD = AIRDROP_MIN_FEE_USD - 1;

        // It should emit a {LowerMinFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.LowerMinFeeUSD(address(comptroller), newMinFeeUSD, AIRDROP_MIN_FEE_USD);

        merkleBase.lowerMinFeeUSD(newMinFeeUSD);

        // It should set the min USD fee to the new lower value.
        assertEq(merkleBase.minFeeUSD(), newMinFeeUSD);
    }

    function test_WhenNewFeeZero() external whenCallerComptroller whenNewFeeLower {
        // It should emit a {LowerMinFeeUSD} event.
        vm.expectEmit({ emitter: address(merkleBase) });
        emit ISablierMerkleBase.LowerMinFeeUSD(address(comptroller), 0, AIRDROP_MIN_FEE_USD);

        merkleBase.lowerMinFeeUSD(0);

        // It should set the new min USD fee to zero.
        assertEq(merkleBase.minFeeUSD(), 0);
    }
}
