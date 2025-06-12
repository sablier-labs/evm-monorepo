// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Base_Test } from "../../../Base.t.sol";

contract NoDelegateCall_Concrete_Test is Base_Test {
    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(noDelegateCallMock.foo, ());
        (bool success, bytes memory returnData) = address(noDelegateCallMock).delegatecall(callData);
        assertFalse(success, "delegatecall success");
        assertEq(returnData, abi.encodeWithSelector(Errors.DelegateCall.selector), "delegatecall return data");
    }

    function test_WhenNoDelegateCall() external view {
        uint256 actual = noDelegateCallMock.foo();
        uint256 expected = 420;
        assertEq(actual, expected, "foo");
    }
}
