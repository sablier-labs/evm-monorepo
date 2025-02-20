// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleFactory } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ResetCustomFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignOwner });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // It should emit a {ResetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.ResetCustomFee({ admin: users.admin, campaignCreator: users.campaignOwner });

        // Reset the custom fee.
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignOwner });

        MerkleFactory.CustomFee memory customFee = merkleFactoryBase.getCustomFee(users.campaignOwner);

        // It should return false.
        assertFalse(customFee.enabled, "custom fee enabled");

        // It should return 0 for the custom fee.
        assertEq(customFee.fee, 0, "custom fee");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Set the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: 1 ether });

        // Check that its enabled.
        MerkleFactory.CustomFee memory customFee = merkleFactoryBase.getCustomFee(users.campaignOwner);

        assertTrue(customFee.enabled, "custom fee not enabled");
        assertEq(customFee.fee, 1 ether, "custom fee");

        // It should emit a {ResetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.ResetCustomFee({ admin: users.admin, campaignCreator: users.campaignOwner });

        // Reset the custom fee.
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignOwner });

        customFee = merkleFactoryBase.getCustomFee(users.campaignOwner);

        // It should disable the custom fee
        assertFalse(customFee.enabled, "custom fee enabled");

        // It should set the custom fee to 0
        assertEq(customFee.fee, 0, "custom fee");
    }
}
