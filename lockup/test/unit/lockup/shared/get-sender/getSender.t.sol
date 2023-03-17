// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetSender_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) { }

    /// @dev it should return zero.
    function test_GetSender_StreamNull() external {
        uint256 nullStreamId = 1729;
        address actualSender = lockup.getSender(nullStreamId);
        address expectedSender = address(0);
        assertEq(actualSender, expectedSender, "sender");
    }

    modifier whenStreamNonNull() {
        _;
    }

    /// @dev it should return the correct sender.
    function test_GetSender() external whenStreamNonNull {
        uint256 streamId = createDefaultStream();
        address actualSender = lockup.getSender(streamId);
        address expectedSender = users.sender;
        assertEq(actualSender, expectedSender, "sender");
    }
}
