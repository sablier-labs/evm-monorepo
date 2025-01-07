// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleFactory } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract SetCustomFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            customFee: 0
        });

        // Set the custom fee.
        merkleFactory.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0 });

        MerkleFactory.CustomFee memory customFee = merkleFactory.getCustomFee(users.campaignOwner);

        // It should enable the custom fee.
        assertTrue(customFee.enabled, "enabled");

        // It should set the custom fee.
        assertEq(customFee.fee, 0, "fee");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        merkleFactory.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 0.001 ether });
        // Check that its enabled.
        MerkleFactory.CustomFee memory customFee = merkleFactory.getCustomFee(users.campaignOwner);
        assertTrue(customFee.enabled, "enabled");
        assertEq(customFee.fee, 0.001 ether, "fee");

        // It should emit a {SetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ISablierMerkleFactory.SetCustomFee({
            admin: users.admin,
            campaignCreator: users.campaignOwner,
            customFee: 1 ether
        });

        // Now set it to a different custom fee.
        merkleFactory.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 1 ether });

        customFee = merkleFactory.getCustomFee(users.campaignOwner);

        // It should enable the custom fee.
        assertTrue(customFee.enabled, "enabled");

        // It should set the custom fee.
        assertEq(customFee.fee, 1 ether, "fee");
    }
}
