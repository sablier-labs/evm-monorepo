// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract DisableCustomFeeUSD_Integration_Test is Integration_Test {
    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Enable the custom fee.
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD not enabled"
        );

        // Disable the custom fee.
        _disableCustomFeeUSD();
    }

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(EvmUtilsErrors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE)
        );
        factoryMerkleBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // Check that custom fee is not enabled.
        assertEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD enabled"
        );

        // Disable the custom fee.
        _disableCustomFeeUSD();
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

        // Disable the custom fee.
        _disableCustomFeeUSD();
    }

    function _disableCustomFeeUSD() private {
        // It should emit a {DisableCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.DisableCustomFeeUSD({ admin: users.admin, campaignCreator: users.campaignCreator });

        // Disable the custom fee.
        factoryMerkleBase.disableCustomFeeUSD({ campaignCreator: users.campaignCreator });

        // It should return the min USD fee.
        assertEq(factoryMerkleBase.minFeeUSDFor(users.campaignCreator), factoryMerkleBase.minFeeUSD(), "custom fee USD");
    }
}
