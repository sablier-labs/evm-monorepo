// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { BatchMock } from "src/mocks/BatchMock.sol";
import { Unit_Test } from "../../Unit.t.sol";

contract Batch_Unit_Concrete_Test is Unit_Test {
    BatchMock internal batchMock;
    bytes[] internal calls;
    uint256 internal newNumber = 100;
    bytes[] internal results;

    function setUp() public override {
        Unit_Test.setUp();

        batchMock = new BatchMock();
    }

    function test_RevertWhen_FunctionDoesNotExist() external {
        calls = new bytes[](1);
        calls[0] = abi.encodeWithSignature("nonExistentFunction()");

        // It should revert.
        vm.expectRevert(bytes(""));
        batchMock.batch(calls);
    }

    modifier whenFunctionExists() {
        _;
    }

    modifier whenNonStateChangingFunction() {
        _;
    }

    function test_RevertWhen_FunctionReverts() external whenFunctionExists whenNonStateChangingFunction {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.getNumberAndRevert, ());

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(BatchMock.InvalidNumber.selector, 1));
        batchMock.batch(calls);
    }

    function test_WhenFunctionNotRevert() external whenFunctionExists whenNonStateChangingFunction {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.getNumber, ());
        results = batchMock.batch(calls);

        // It should return the expected value.
        assertEq(results.length, 1, "batch results length");
        assertEq(abi.decode(results[0], (uint256)), 42, "batch results[0]");
    }

    modifier whenStateChangingFunction() {
        _;
    }

    modifier whenNotPayable() {
        _;
    }

    function test_RevertWhen_BatchIncludesETHValue()
        external
        whenFunctionExists
        whenStateChangingFunction
        whenNotPayable
    {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.setNumber, (newNumber));

        // It should revert.
        vm.expectRevert(bytes(""));
        batchMock.batch{ value: 1 wei }(calls);
    }

    function test_WhenBatchNotIncludeETHValue() external whenFunctionExists whenStateChangingFunction whenNotPayable {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.setNumber, (newNumber));

        results = batchMock.batch(calls);

        // It should return the empty string.
        assertEq(results.length, 1, "batch results length");
        assertEq(results[0], "", "batch results[0]");
    }

    modifier whenPayable() {
        _;
    }

    function test_RevertWhen_FunctionRevertsWithCustomError()
        external
        whenFunctionExists
        whenStateChangingFunction
        whenPayable
    {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.setNumberWithPayableAndRevertError, (newNumber));

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(BatchMock.InvalidNumber.selector, newNumber));
        batchMock.batch{ value: 1 wei }(calls);
    }

    function test_RevertWhen_FunctionRevertsWithStringError()
        external
        whenFunctionExists
        whenStateChangingFunction
        whenPayable
    {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.setNumberWithPayableAndRevertString, (newNumber));

        // It should revert.
        vm.expectRevert("You cannot pass");
        batchMock.batch{ value: 1 wei }(calls);
    }

    function test_WhenFunctionReturnsAValue() external whenFunctionExists whenStateChangingFunction whenPayable {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.setNumberWithPayableAndReturn, (newNumber));
        results = batchMock.batch{ value: 1 wei }(calls);

        // It should return expected value.
        assertEq(results.length, 1, "batch results length");
        assertEq(abi.decode(results[0], (uint256)), newNumber, "batch results[0]");
    }

    function test_WhenFunctionDoesNotReturnAValue() external whenFunctionExists whenStateChangingFunction whenPayable {
        calls = new bytes[](1);
        calls[0] = abi.encodeCall(batchMock.setNumberWithPayable, (newNumber));
        results = batchMock.batch{ value: 1 wei }(calls);

        // It should return an empty value.
        assertEq(results.length, 1, "batch results length");
        assertEq(results[0], "", "batch results[0]");
    }
}
