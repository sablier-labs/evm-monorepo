// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors as EvmUtilsErrors } from "@sablier/evm-utils/src/libraries/Errors.sol";
import { ISablierFactoryMerkleBase } from "src/interfaces/ISablierFactoryMerkleBase.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "./../../../../Integration.t.sol";

abstract contract SetCustomFeeUSD_Integration_Test is Integration_Test {
    function test_WhenCallerWithFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.accountant);

        // Set the custom fee.
        _setCustomFeeUSD();
    }

    function test_RevertWhen_CallerWithoutFeeManagementRole() external whenCallerNotAdmin {
        setMsgSender(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(EvmUtilsErrors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE)
        );
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0 });
    }

    function test_RevertWhen_NewFeeExceedsMaxFee() external whenCallerAdmin {
        uint256 customFeeUSD = MAX_FEE_USD + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierFactoryMerkleBase_MaxFeeUSDExceeded.selector, customFeeUSD, MAX_FEE_USD
            )
        );
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: customFeeUSD });
    }

    function test_WhenNotEnabled() external whenCallerAdmin {
        // Check that custom fee is not enabled for user.
        assertEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD enabled"
        );

        // Set the custom fee.
        _setCustomFeeUSD();
    }

    function test_WhenEnabled() external whenCallerAdmin whenNewFeeNotExceedMaxFee {
        // Enable the custom fee.
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: 0.5e8 });

        // Check that custom fee is enabled.
        assertNotEq(
            factoryMerkleBase.minFeeUSDFor(users.campaignCreator),
            factoryMerkleBase.minFeeUSD(),
            "custom fee USD not enabled"
        );

        // Set the custom fee.
        _setCustomFeeUSD();
    }

    function _setCustomFeeUSD() private {
        // Set the custom fee to a different value.
        uint256 customFeeUSD = 0;

        // It should emit a {SetCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(factoryMerkleBase) });
        emit ISablierFactoryMerkleBase.SetCustomFeeUSD({
            admin: users.admin,
            campaignCreator: users.campaignCreator,
            customFeeUSD: customFeeUSD
        });

        // Set the custom fee.
        factoryMerkleBase.setCustomFeeUSD({ campaignCreator: users.campaignCreator, customFeeUSD: customFeeUSD });

        // It should set the custom fee.
        assertEq(factoryMerkleBase.minFeeUSDFor(users.campaignCreator), customFeeUSD, "custom fee USD");
    }
}
