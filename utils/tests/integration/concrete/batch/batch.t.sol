// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { BatchMock } from "src/mocks/BatchMock.sol";
import { Base_Test } from "../../../Base.t.sol";

contract Batch_Concrete_Test is Base_Test {
    bytes[] internal calls;
    uint256 internal newNumber = 100;
    bytes[] internal results;

    function test_RevertWhen_FunctionDoesNotExist() external {
        calls = new bytes[](1);
        calls[0] = abi.encodeWithSignature("nonExistentFunction()");

        // It should revert.
        vm.expectRevert(bytes(""));
        batch.batch(calls);
    }

    function test_RevertWhen_FunctionReverts() external whenFunctionExists whenNonStateChangingFunction {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.getNumberAndRevert, ());

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(BatchMock.InvalidNumber.selector, 1));
        batch.batch(calls);
    }

    function test_WhenFunctionNotRevert() external whenFunctionExists whenNonStateChangingFunction {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.getNumber, ());
        results = batch.batch(calls);

        // It should return the expected value.
        assertEq(results.length, 1, "batch results length");
        assertEq(abi.decode(results[0], (uint256)), 42, "batch results[0]");
    }

    function test_RevertWhen_BatchIncludesETHValue()
        external
        whenFunctionExists
        whenStateChangingFunction
        whenNotPayable
    {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.setNumber, (newNumber));

        // It should revert.
        vm.expectRevert(bytes(""));
        batch.batch{ value: 1 wei }(calls);
    }

    function test_WhenBatchNotIncludeETHValue() external whenFunctionExists whenStateChangingFunction whenNotPayable {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.setNumber, (newNumber));

        results = batch.batch(calls);

        // It should return the empty string.
        assertEq(results.length, 1, "batch results length");
        assertEq(results[0], "", "batch results[0]");
    }

    function test_RevertWhen_FunctionRevertsWithCustomError()
        external
        whenFunctionExists
        whenStateChangingFunction
        whenPayable
    {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.setNumberWithPayableAndRevertError, (newNumber));

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(BatchMock.InvalidNumber.selector, newNumber));
        batch.batch{ value: 1 wei }(calls);
    }

    function test_RevertWhen_FunctionRevertsWithStringError()
        external
        whenFunctionExists
        whenStateChangingFunction
        whenPayable
    {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.setNumberWithPayableAndRevertString, (newNumber));

        // It should revert.
        vm.expectRevert("You cannot pass");
        batch.batch{ value: 1 wei }(calls);
    }

    function test_WhenFunctionReturnsAValue() external whenFunctionExists whenStateChangingFunction whenPayable {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.setNumberWithPayableAndReturn, (newNumber));
        results = batch.batch{ value: 1 wei }(calls);

        // It should return expected value.
        assertEq(results.length, 1, "batch results length");
        assertEq(abi.decode(results[0], (uint256)), newNumber, "batch results[0]");
    }

    function test_WhenFunctionDoesNotReturnAValue() external whenFunctionExists whenStateChangingFunction whenPayable {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batch.setNumberWithPayable, (newNumber));
        results = batch.batch{ value: 1 wei }(calls);

        // It should return an empty value.
        assertEq(results.length, 1, "batch results length");
        assertEq(results[0], "", "batch results[0]");
    }
}
