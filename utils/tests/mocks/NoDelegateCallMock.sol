// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { NoDelegateCall } from "src/NoDelegateCall.sol";

contract NoDelegateCallMock is NoDelegateCall {
    /// @dev An empty function that uses the `noDelegateCall` modifier.
    function foo() public view noDelegateCall returns (uint256) {
        return 420;
    }
}
