// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract GetRecipient_Unit_Test is Unit_Test, Lockup_Shared_Test {
    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {}

    /// @dev it should return zero.
    function test_GetRecipient_StreamNull() external {
        uint256 nullStreamId = 1729;
        address actualRecipient = lockup.getRecipient(nullStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }

    modifier streamNonNull() {
        _;
    }

    /// @dev it should return the correct recipient.
    function test_GetRecipient() external streamNonNull {
        uint256 streamId = createDefaultStream();
        address actualRecipient = lockup.getRecipient(streamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient, "recipient");
    }
}
