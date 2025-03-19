// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetMinimumFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setMinimumFee(0.001e18);
    }

    function test_RevertWhen_NewFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newFee = MAX_FEE + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactoryBase_MaximumFeeExceeded.selector, newFee, MAX_FEE)
        );
        merkleFactoryBase.setMinimumFee(newFee);
    }

    function test_WhenNewFeeNotExceedMaxFee() external whenCallerAdmin {
        uint256 newFee = MAX_FEE;

        // It should emit a {SetMinimumFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetMinimumFee({ admin: users.admin, minimumFee: newFee });

        merkleFactoryBase.setMinimumFee(newFee);

        // It should set the minimum fee.
        assertEq(merkleFactoryBase.minimumFee(), newFee, "minimum fee");
    }
}
