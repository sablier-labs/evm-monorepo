// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { IOwnable } from "@prb/contracts/access/IOwnable.sol";
import { UD60x18, unwrap, wrap } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract ClaimProtocolRevenues__Test is LinearTest {
    /// @dev it should revert.
    function testCannotClaimProtocolRevenues__CallerNotOwner() external {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(IOwnable.Ownable__CallerNotOwner.selector, users.owner, users.eve));
        linear.claimProtocolRevenues(address(dai));
    }

    modifier CallerOwner() {
        // Make the owner the caller in the rest of this test suite.
        changePrank(users.owner);
        _;
    }

    /// @dev it should revert.
    function testCannotClaimProtocolRevenues__ProtocolRevenuesZero() external CallerOwner {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__ClaimZeroProtocolRevenues.selector, address(dai)));
        linear.claimProtocolRevenues(address(dai));
    }

    modifier ProtocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank(users.sender);
        createDefaultStream();
        changePrank(users.owner);
        _;
    }

    /// @dev it should claim the protocol revenues.
    function testClaimProtocolRevenues() external CallerOwner ProtocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.owner, protocolRevenues)));

        // Claim the protocol revenues.
        linear.claimProtocolRevenues(address(dai));
    }

    /// @dev it should set the protocol revenues to zero.
    function testClaimProtocolRevenues__SetToZero() external CallerOwner ProtocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (users.owner, protocolRevenues)));

        // Claim the protocol revenues.
        linear.claimProtocolRevenues(address(dai));

        // Assert that the protocol revenues were set to zero.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(address(dai));
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    /// @dev it should emit a ClaimProtocolRevenues event.
    function testClaimProtocolRevenues__Event() external CallerOwner ProtocolRevenuesNotZero {
        // Expect the protocol revenues to be claimed.
        uint128 protocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.ClaimProtocolRevenues(users.owner, address(dai), protocolRevenues);

        // Claim the protocol revenues.
        linear.claimProtocolRevenues(address(dai));
    }
}
