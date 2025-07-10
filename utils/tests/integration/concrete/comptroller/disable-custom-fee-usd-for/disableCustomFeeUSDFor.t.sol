// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierComptroller } from "src/interfaces/ISablierComptroller.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "tests/Base.t.sol";

contract DisableCustomFeeUSDFor_Comptroller_Concrete_Test is Base_Test {
    function setUp() public override {
        Base_Test.setUp();

        // Set custom fee for sender.
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Airdrops, users.sender, 0);
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Flow, users.sender, 0);
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Lockup, users.sender, 0);
        comptroller.setCustomFeeUSDFor(ISablierComptroller.Protocol.Staking, users.sender, 0);
    }

    function test_RevertWhen_CallerWithoutFeeManagementRole(uint8 protocolIndex) external whenCallerNotAdmin {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        setMsgSender(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.UnauthorizedAccess.selector, users.eve, FEE_MANAGEMENT_ROLE));
        comptroller.disableCustomFeeUSDFor(protocol, users.sender);
    }

    function test_WhenCallerWithFeeManagementRole(uint8 protocolIndex) external whenCallerNotAdmin {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);
        setMsgSender(users.accountant);

        // Disable the custom fee.
        _disableCustomFeeUSDFor(protocol);
    }

    function test_WhenCallerAdmin(uint8 protocolIndex) external {
        ISablierComptroller.Protocol protocol = boundProtocolEnum(protocolIndex);

        // Disable the custom fee.
        _disableCustomFeeUSDFor(protocol);
    }

    /// @dev Shared logic to test disabling the custom fee.
    function _disableCustomFeeUSDFor(ISablierComptroller.Protocol protocol) private {
        // Check that custom fee is set.
        assertEq(comptroller.calculateMinFeeWeiFor(protocol, users.sender), 0, "custom fee set");

        // It should emit a {DisableCustomFeeUSD} event.
        vm.expectEmit({ emitter: address(comptroller) });
        emit ISablierComptroller.DisableCustomFeeUSD(protocol, users.sender);

        // Disable the custom fee.
        comptroller.disableCustomFeeUSDFor(protocol, users.sender);

        // It should disable the custom fee.
        assertEq(comptroller.calculateMinFeeWeiFor(protocol, users.sender), getFeeInWei(protocol), "custom fee not set");
        assertNotEq(comptroller.calculateMinFeeWeiFor(protocol, users.sender), 0, "custom fee not disabled");
    }
}
