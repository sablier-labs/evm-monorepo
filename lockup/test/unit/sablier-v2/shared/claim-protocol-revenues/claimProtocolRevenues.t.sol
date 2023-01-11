// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IAdminable } from "@prb/contracts/access/IAdminable.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract ClaimProtocolRevenues_Test is SharedTest {
    /// @dev it should revert.
    function test_RevertWhen_CallerNotAdmin() external {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IAdminable.Adminable_CallerNotAdmin.selector, users.admin, users.eve));
        sablierV2.claimProtocolRevenues(dai);
    }

    modifier callerAdmin() {
        // Make the admin the caller in the rest of this test suite.
        changePrank(users.admin);
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ProtocolRevenuesZero() external callerAdmin {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_ClaimZeroProtocolRevenues.selector, dai));
        sablierV2.claimProtocolRevenues(dai);
    }

    modifier protocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank(users.sender);
        createDefaultStream();
        changePrank(users.admin);
        _;
    }

    /// @dev it should claim the protocol revenues.
    function test_ClaimProtocolRevenues() external callerAdmin protocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.admin, protocolRevenues)));

        // Claim the protocol revenues.
        sablierV2.claimProtocolRevenues(dai);
    }

    /// @dev it should set the protocol revenues to zero.
    function test_ClaimProtocolRevenues_SetToZero() external callerAdmin protocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.admin, protocolRevenues)));

        // Claim the protocol revenues.
        sablierV2.claimProtocolRevenues(dai);

        // Assert that the protocol revenues were set to zero.
        uint128 actualProtocolRevenues = sablierV2.getProtocolRevenues(dai);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a ClaimProtocolRevenues event.
    function test_ClaimProtocolRevenues_Event() external callerAdmin protocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ClaimProtocolRevenues(users.admin, dai, protocolRevenues);

        // Claim the protocol revenues.
        sablierV2.claimProtocolRevenues(dai);
    }
}
