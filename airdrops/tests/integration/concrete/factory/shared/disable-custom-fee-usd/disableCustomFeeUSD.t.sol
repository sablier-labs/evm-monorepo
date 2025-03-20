// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract DisableCustomFeeUSD_Integration_Test is Integration_Test {
    function test_RevertWhen_CallerNotAdmin() external {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(EvmUtilsErrors.CallerNotAdmin.selector, users.admin, users.eve));
        factoryMerkleBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // Check that custom fee is not enabled.
        assertEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD enabled"
        );

        // It should emit a {DisableCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.DisableCustomFeeUSD({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Reset the custom fee.
        factoryMerkleBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // It should return the min fee.
        assertEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD changed"
        );
    }

    function test_WhenEnabled() external whenCallerAdmin {
        // Enable the custom fee.
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD not enabled"
        );

        // It should emit a {DisableCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.DisableCustomFeeUSD({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Disable the custom fee.
        factoryMerkleBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // It should return the min USD fee.
        assertEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD not changed"
        );
    }
}
