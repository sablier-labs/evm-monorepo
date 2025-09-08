// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "tests/Base.t.sol";

contract SetCustomFeeUSDFor_Comptroller_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerWithoutFeeManagementRole(
        uint8 protocolIndex,
        address user
    )
        external
        whenCallerNotAdmin
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setCustomFeeUSDFor(protocol, user, 0);
    }

    function test_WhenCallerWithFeeManagementRole(
        uint8 protocolIndex,
        address user,
        uint128 customFeeUSD
    )
        external
        whenCallerNotAdmin
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to the max fee USD.
        customFeeUSD = boundUint128(customFeeUSD, 0, uint128(MAX_FEE_USD));

        setMsgSender(users.accountant);

        // Set the custom fee.
        _setCustomFeeUSDFor({
            protocol: protocol,
            caller: users.accountant,
            user: user,
            currentFeeUSD: getFeeInUSD(protocol),
            newCustomFeeUSD: customFeeUSD
        });
    }

    function test_RevertWhen_NewFeeExceedsMaxFee(
        uint8 protocolIndex,
        address user,
        uint128 customFeeUSD
    )
        external
        whenCallerAdmin
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to exceed the max fee USD.
        customFeeUSD = boundUint128(customFeeUSD, uint128(MAX_FEE_USD) + 1, MAX_UINT128);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, customFeeUSD, MAX_FEE_USD)
        );
        comptroller.setCustomFeeUSDFor(protocol, user, customFeeUSD);
    }

    function test_WhenNotEnabled(
        uint8 protocolIndex,
        address user,
        uint128 customFeeUSD
    )
        external
        whenCallerAdmin
        whenNewFeeNotExceedMaxFee
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to the max fee USD.
        customFeeUSD = boundUint128(customFeeUSD, 0, uint128(MAX_FEE_USD));

        // Check that custom fee is not enabled for user.
        assertEq(comptroller.calculateMinFeeWeiFor(protocol, user), getFeeInWei(protocol), "custom fee USD enabled");

        // Set the custom fee.
        _setCustomFeeUSDFor({
            protocol: protocol,
            caller: admin,
            user: user,
            currentFeeUSD: getFeeInUSD(protocol),
            newCustomFeeUSD: customFeeUSD
        });
    }

    function test_WhenEnabled(
        uint8 protocolIndex,
        address user,
        uint128 customFeeUSD
    )
        external
        whenCallerAdmin
        whenNewFeeNotExceedMaxFee
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to the max fee USD.
        customFeeUSD = boundUint128(customFeeUSD, 0, uint128(MAX_FEE_USD));

        // Enable the custom fee.
        comptroller.setCustomFeeUSDFor(protocol, user, customFeeUSD);

        // Check that custom fee is enabled.
        assertEq(comptroller.getMinFeeUSDFor(protocol, user), customFeeUSD, "custom fee USD not enabled");

        // Set the custom fee.
        _setCustomFeeUSDFor({
            protocol: protocol,
            caller: admin,
            user: user,
            currentFeeUSD: customFeeUSD,
            newCustomFeeUSD: customFeeUSD
        });
    }

    /// @dev Shared logic to test setting the custom fee.
    function _setCustomFeeUSDFor(
        ISablierComptroller.Protocol protocol,
        address caller,
        address user,
        uint256 currentFeeUSD,
        uint128 newCustomFeeUSD
    )
        private
    {
        // It should emit a {SetCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetCustomFeeUSD(protocol, caller, user, currentFeeUSD, newCustomFeeUSD);

        // Set the custom fee.
        comptroller.setCustomFeeUSDFor(protocol, user, newCustomFeeUSD);

        // It should set the custom fee.
        assertEq(comptroller.getMinFeeUSDFor(protocol, user), newCustomFeeUSD, "custom fee USD");
    }
}
