// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as CoreErrors } from "src/core/libraries/Errors.sol";

import { MerkleCampaign_Integration_Shared_Test } from "../../shared/MerkleCampaign.t.sol";

contract SetDefaultSablierFee_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(CoreErrors.CallerNotAdmin.selector, users.admin, users.eve));
        merkleFactory.setDefaultSablierFee({ defaultFee: sablierFee });
    }

    function test_WhenCallerAdmin() external {
        resetPrank({ msgSender: users.admin });

        // It should emit a {SetDefaultSablierFee} event.
        vm.expectEmit({ emitter: address(merkleFactory) });
        emit SetDefaultSablierFee({ admin: users.admin, sablierFee: defaults.DEFAULT_SABLIER_FEE() });

        merkleFactory.setDefaultSablierFee({ defaultFee: defaults.DEFAULT_SABLIER_FEE() });

        // It should set the default Sablier fee.
        assertEq(merkleFactory.defaultSablierFee(), defaults.DEFAULT_SABLIER_FEE(), "sablier fee");
    }
}
