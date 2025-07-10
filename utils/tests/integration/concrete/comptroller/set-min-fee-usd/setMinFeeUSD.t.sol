// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "tests/Base.t.sol";

contract SetMinFeeUSD_Comptroller_Concrete_Test is Base_Test {
    function test_RevertWhen_CallerWithoutFeeManagementRole(uint8 protocolIndex) external whenCallerNotAdmin {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.setMinFeeUSD(protocol, 0);
    }

    function test_WhenCallerWithFeeManagementRole(
        uint8 protocolIndex,
        uint128 newMinFeeUSD
    )
        external
        whenCallerNotAdmin
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to the max fee USD.
        newMinFeeUSD = boundUint128(newMinFeeUSD, 0, uint128(MAX_FEE_USD));

        setMsgSender(users.accountant);

        // Set the min fee USD.
        _setMinFeeUSD(protocol, users.accountant, newMinFeeUSD);
    }

    function test_RevertWhen_NewMinFeeExceedsMaxFee(
        uint8 protocolIndex,
        uint128 newMinFeeUSD
    )
        external
        whenCallerAdmin
    {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to exceed the max fee USD.
        newMinFeeUSD = boundUint128(newMinFeeUSD, uint128(MAX_FEE_USD) + 1, MAX_UINT128);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierComptroller_MaxFeeUSDExceeded.selector, newMinFeeUSD, MAX_FEE_USD)
        );
        comptroller.setMinFeeUSD(protocol, newMinFeeUSD);
    }

    function test_WhenNewMinFeeNotExceedMaxFee(uint8 protocolIndex, uint128 newMinFeeUSD) external whenCallerAdmin {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Bound custom fee USD to the max fee USD.
        newMinFeeUSD = boundUint128(newMinFeeUSD, 0, uint128(MAX_FEE_USD));

        // Set the min fee USD.
        _setMinFeeUSD(protocol, admin, newMinFeeUSD);
    }

    /// @dev Shared logic to test setting the min fee USD.
    function _setMinFeeUSD(ISablierComptroller.Protocol protocol, address caller, uint128 newMinFeeUSD) private {
        uint256 previousMinFeeUSD = comptroller.getMinFeeUSD(protocol);

        // It should emit a {SetMinFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.SetMinFeeUSD(protocol, caller, previousMinFeeUSD, newMinFeeUSD);

        comptroller.setMinFeeUSD(protocol, newMinFeeUSD);

        // It should set the min fee USD.
        assertEq(comptroller.getMinFeeUSD(protocol), newMinFeeUSD, "min fee USD");
    }
}
