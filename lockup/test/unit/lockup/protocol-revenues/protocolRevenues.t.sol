// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../Unit.t.sol";

abstract contract ProtocolRevenues_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    function test_ProtocolRevenues_ProtocolRevenuesZero() external {
        uint128 actualProtocolRevenues = base.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = 0;
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }

    modifier whenProtocolRevenuesNotZero() {
        // Create the default stream, which will accrue revenues for the protocol.
        changePrank({ msgSender: users.sender });
        createDefaultStream();
        changePrank({ msgSender: users.admin });
        _;
    }

    function test_ProtocolRevenues() external whenProtocolRevenuesNotZero {
        uint128 actualProtocolRevenues = base.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = defaults.PROTOCOL_FEE_AMOUNT();
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
