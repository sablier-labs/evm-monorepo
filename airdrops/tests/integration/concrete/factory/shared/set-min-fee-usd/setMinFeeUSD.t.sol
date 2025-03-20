// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetMinFeeUSD_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        factoryMerkleBase.setMinFeeUSD(0.001e18);
    }

    function test_RevertWhen_NewMinFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleBase_MaxFeeUSDExceeded.selector, newMinFeeUSD, MAX_FEE_USD
            )
        );
        factoryMerkleBase.setMinFeeUSD(newMinFeeUSD);
    }

    function test_WhenNewMinFeeNotExceedMaxFee() external whenCallerAdmin {
        uint256 newMinFeeUSD = MAX_FEE_USD;

        // It should emit a {SetMinFeeUSD} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.SetMinFeeUSD({
            admin: users.admin,
            newMinFeeUSD: newMinFeeUSD,
            previousMinFeeUSD: MIN_FEE_USD
        });

        factoryMerkleBase.setMinFeeUSD(newMinFeeUSD);

        // It should set the min USD fee.
        assertEq(factoryMerkleBase.minFeeUSD(), newMinFeeUSD, "min fee USD");
    }
}
