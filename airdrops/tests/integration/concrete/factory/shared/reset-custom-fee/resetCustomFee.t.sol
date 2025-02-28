// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierMerkleFactoryBase } from "src/interfaces/ISablierMerkleFactoryBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract ResetCustomFee_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignOwner });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // It should emit a {ResetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.ResetCustomFee({ admin: users.admin, campaignCreator: users.campaignOwner });

        // Reset the custom fee.
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignOwner });

        // It should return the minimum fee.
        assertEq(merkleFactoryBase.getFee(users.campaignOwner), MINIMUM_FEE, "custom fee");
    }

    function test_WhenEnabled() external whenCallerAdmin {
        uint256 customFee = 0.5e8;
        // Set the custom fee.
        merkleFactoryBase.setCustomFee({ campaignCreator: users.campaignOwner, newFee: customFee });

        assertEq(merkleFactoryBase.getFee(users.campaignOwner), customFee, "custom fee");

        // It should emit a {ResetCustomFee} event.
        vm.expectEmit({ emitter: address(merkleFactoryBase) });
        emit ISablierMerkleFactoryBase.ResetCustomFee({ admin: users.admin, campaignCreator: users.campaignOwner });

        // Reset the custom fee.
        merkleFactoryBase.resetCustomFee({ campaignCreator: users.campaignOwner });

        assertEq(merkleFactoryBase.getFee(users.campaignOwner), MINIMUM_FEE, "fee");
    }
}
