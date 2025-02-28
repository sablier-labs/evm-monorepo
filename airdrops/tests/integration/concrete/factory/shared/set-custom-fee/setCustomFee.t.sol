// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetCustomFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });
    }

    function test_RevertWhen_NewFeeExceedsTheMaximumFee() external whenCallerAdmin {
        resetPrank({ msgSender: users.admin });
        uint256 newFee = MAX_FEE + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactoryBase_MaximumFeeExceeded.selector, newFee, MAX_FEE)
        );
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: newFee });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        uint256 newFee = 0;

        assertNotEq(merkleFactoryBase.getFee(users.campaignOwner), newFee, "custom fee");

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            customFee: newFee
        });

        // Set the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: newFee });

        // It should set the custom fee.
        assertEq(merkleFactoryBase.getFee(users.campaignOwner), newFee, "custom fee");
    }

    function test_WhenEnabled() external whenCallerAdmin whenNewFeeDoesNotExceedTheMaximumFee {
        // Set the custom fee.
        uint256 customFee = 0.5e8;

        assertNotEq(merkleFactoryBase.getFee(users.campaignOwner), customFee, "custom fee");

        // Enable the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: customFee });

        // Check that its enabled.
        assertEq(merkleFactoryBase.getFee(users.campaignOwner), customFee, "custom fee");

        // Now set it to a different custom fee.
        customFee = 0;

        assertNotEq(merkleFactoryBase.getFee(users.campaignOwner), customFee, "custom fee");

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            customFee: customFee
        });

        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: customFee });

        assertEq(merkleFactoryBase.getFee(users.campaignOwner), customFee, "custom fee");
    }
}
