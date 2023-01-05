// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IOwnable } from "@prb/contracts/access/IOwnable.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SharedTest } from "test/unit/sablier-v2/shared/SharedTest.t.sol";

abstract contract GetProtocolRevenues__Test is SharedTest {
    /// @dev it should return zero.
    function testGetProtocolRevenues__ProtocolRevenuesZero() external {
        uint128 actualProtocolRevenues = sablierV2.getProtocolRevenues(dai);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }

    modifier ProtocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank(users.sender);
        createDefaultStream();
        changePrank(users.owner);
        _;
    }

    /// @dev it should return the correct protocol revenues.
    function testGetProtocolRevenues() external ProtocolRevenuesNotZero {
        uint128 actualProtocolRevenues = sablierV2.getProtocolRevenues(dai);
        uint128 expectedProtocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }
}
