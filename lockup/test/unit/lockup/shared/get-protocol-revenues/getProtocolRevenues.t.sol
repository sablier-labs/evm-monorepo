// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IAdminable } from "@prb/contracts/access/IAdminable.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { Shared_Lockup_Unit_Test } from "../SharedTest.t.sol";

abstract contract GetProtocolRevenues_Unit_Test is Shared_Lockup_Unit_Test {
    /// @dev it should return zero.
    function test_GetProtocolRevenues_ProtocolRevenuesZero() external {
        uint128 actualProtocolRevenues = sablierV2.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }

    modifier protocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank(users.sender);
        createDefaultStream();
        changePrank(users.admin);
        _;
    }

    /// @dev it should return the correct protocol revenues.
    function test_GetProtocolRevenues() external protocolRevenuesNotZero {
        uint128 actualProtocolRevenues = sablierV2.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = DEFAULT_PROTOCOL_FEE_AMOUNT;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
