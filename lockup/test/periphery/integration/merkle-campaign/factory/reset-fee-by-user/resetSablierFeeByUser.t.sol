// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as CoreErrors } from "src/core/libraries/Errors.sol";

import { MerkleFactory } from "src/periphery/types/DataTypes.sol";

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

contract ResetSablierFeeByUser_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(CoreErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.resetSablierFeeByUser({ campaignCreator: users.campaignOwner });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // It should emit a {ResetSablierFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ResetSablierFee({ admin: users.admin, campaignCreator: users.campaignOwner });

        // Reset the Sablier fee.
        merkleFactory.resetSablierFeeByUser({ campaignCreator: users.campaignOwner });

        MerkleFactory.SablierFeeByUser memory sablierFee = merkleFactory.sablierFeeByUser(users.campaignOwner);

        // It should return false.
        assertFalse(sablierFee.enabled, "enabled");

        // It should return 0 for the Sablier fee.
        assertEq(sablierFee.fee, 0, "fee");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the Sablier fee.
        merkleFactory.setSablierFeeByUser({ campaignCreator: users.campaignOwner, fee: 1 ether });

        // Check that its enabled.
        MerkleFactory.SablierFeeByUser memory sablierFee = merkleFactory.sablierFeeByUser(users.campaignOwner);

        assertTrue(sablierFee.enabled, "enabled");
        assertEq(sablierFee.fee, 1 ether, "fee");

        // It should emit a {ResetSablierFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit ResetSablierFee({ admin: users.admin, campaignCreator: users.campaignOwner });

        // Reset the Sablier fee.
        merkleFactory.resetSablierFeeByUser({ campaignCreator: users.campaignOwner });

        sablierFee = merkleFactory.sablierFeeByUser(users.campaignOwner);

        // It should disable the Sablier fee
        assertFalse(sablierFee.enabled, "enabled");

        // It should set the Sablier fee to 0
        assertEq(sablierFee.fee, 0, "fee");
    }
}
