// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { MerkleFactory } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract SetCustomFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            customFee: 0
        });

        // Set the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });

        MerkleFactory.CustomFee memory customFee = merkleFactoryBase.getCustomFee(users.campaignOwner);

        // It should enable the custom fee.
        assertTrue(customFee.enabled, "custom fee not enabled");

        // It should set the custom fee.
        assertEq(customFee.fee, 0, "custom fee");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0.001 ether });
        // Check that its enabled.
        MerkleFactory.CustomFee memory customFee = merkleFactoryBase.getCustomFee(users.campaignOwner);
        assertTrue(customFee.enabled, "custom fee not enabled");
        assertEq(customFee.fee, 0.001 ether, "custom fee");

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            customFee: 1 ether
        });

        // Now set it to a different custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 1 ether });

        customFee = merkleFactoryBase.getCustomFee(users.campaignOwner);

        // It should enable the custom fee.
        assertTrue(customFee.enabled, "custom fee not enabled");

        // It should set the custom fee.
        assertEq(customFee.fee, 1 ether, "custom fee");
    }
}
