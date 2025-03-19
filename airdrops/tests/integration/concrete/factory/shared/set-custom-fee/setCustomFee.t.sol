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
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignCreator, newFee: 0 });
    }

    function test_RevertWhen_NewFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 newFee = MAX_FEE + 1;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleFactoryBase_MaximumFeeExceeded.selector, newFee, MAX_FEE)
        );
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignCreator, newFee: newFee });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // Check that custom fee is not enabled for user.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minimumFee(), "custom fee enabled");

        uint256 customFee = 0;

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignCreator,
            customFee: customFee
        });

        // Set the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignCreator, newFee: customFee });

        // It should set the custom fee.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), customFee, "custom fee");
    }

    function test_WhenEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        // Enable the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignCreator, newFee: 0.5e8 });

        // Check that custom fee is enabled for user by checking that it is not equal to the minimum fee.
        assertNotEq(
            merkleFactoryBase.getFee(users.campaignCreator), merkleFactoryBase.minimumFee(), "custom fee not enabled"
        );

        // Now set the custom fee to a different value.
        uint256 customFee = 0;

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignCreator,
            customFee: customFee
        });

        // Set the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignCreator, newFee: customFee });

        // It should set the custom fee.
        assertEq(merkleFactoryBase.getFee(users.campaignCreator), customFee, "custom fee");
    }
}
