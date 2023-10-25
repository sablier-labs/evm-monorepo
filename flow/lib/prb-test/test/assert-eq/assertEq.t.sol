// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import "../../src/Helpers.sol" as Helpers;

import { PRBTest_Test } from "../PRBTest.t.sol";

contract AssertEq_Test is PRBTest_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                    BASIC TYPES
    //////////////////////////////////////////////////////////////////////////*/

    function test_AssertEq_Address_Fail(address a, address b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [address]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Address_Err_Fail(address a, address b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Address_Err_Pass(address a) external {
        prbTest._assertEq(a, a, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Address_Pass(address a) external {
        prbTest._assertEq(a, a, EXPECT_PASS);
    }

    function test_AssertEq_Bool_Fail() external {
        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bool]");
        prbTest._assertEq({ a: false, b: true, expectFail: EXPECT_FAIL });

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bool]");
        prbTest._assertEq({ a: true, b: false, expectFail: EXPECT_FAIL });
    }

    function test_AssertEq_Bool_Err_Fail() external {
        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq({ a: false, b: true, err: ERR, expectFail: EXPECT_FAIL });

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq({ a: true, b: false, err: ERR, expectFail: EXPECT_FAIL });
    }

    function test_AssertEq_Bool_Err_Pass() external {
        prbTest._assertEq({ a: false, b: false, err: ERR, expectFail: EXPECT_PASS });
        prbTest._assertEq({ a: true, b: true, err: ERR, expectFail: EXPECT_PASS });
    }

    function test_AssertEq_Bool_Pass() external {
        prbTest._assertEq({ a: false, b: false, expectFail: EXPECT_PASS });
        prbTest._assertEq({ a: true, b: true, expectFail: EXPECT_PASS });
    }

    function test_AssertEq_Bytes_Fail(bytes memory a, bytes memory b) external {
        vm.assume(!Helpers.eq(a, b));

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bytes]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes_Err_Fail(bytes memory a, bytes memory b) external {
        vm.assume(!Helpers.eq(a, b));

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes_Err_Pass(bytes memory a) external {
        prbTest._assertEq(a, a, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Bytes_Pass(bytes memory a) external {
        prbTest._assertEq(a, a, EXPECT_PASS);
    }

    function test_AssertEq_Bytes32_Fail(bytes32 a, bytes32 b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bytes32]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes32_Err_Fail(bytes32 a, bytes32 b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes32_Err_Pass(bytes32 a) external {
        prbTest._assertEq(a, a, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Bytes32_Pass(bytes32 a) external {
        prbTest._assertEq(a, a, EXPECT_PASS);
    }

    function test_AssertEq_Int256_Fail(int256 a, int256 b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [int256]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Int256_Err_Fail(int256 a, int256 b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Int256_Err_Pass(int256 a) external {
        prbTest._assertEq(a, a, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Int256_Pass(int256 a) external {
        prbTest._assertEq(a, a, EXPECT_PASS);
    }

    function test_AssertEq_String_Fail(string memory a, string memory b) external {
        vm.assume(!Helpers.eq(a, b));

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [string]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_String_Err_Fail(string memory a, string memory b) external {
        vm.assume(!Helpers.eq(a, b));

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_String_Err_Pass(string memory a) external {
        prbTest._assertEq(a, a, ERR, EXPECT_PASS);
    }

    function test_AssertEq_String_Pass(string memory a) external {
        prbTest._assertEq(a, a, EXPECT_PASS);
    }

    function test_AssertEq_Uint256_Fail(uint256 a, uint256 b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [uint256]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Uint256_Err_Fail(uint256 a, uint256 b) external {
        vm.assume(a != b);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Uint256_Err_Pass(uint256 a) external {
        prbTest._assertEq(a, a, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Uint256_Pass(uint256 a) external {
        prbTest._assertEq(a, a, EXPECT_PASS);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        ARRAYS
    //////////////////////////////////////////////////////////////////////////*/

    function test_AssertEq_AddressArray_FailElements(address e1) external {
        vm.assume(e1 != address(0));

        address[] memory a = new address[](3);
        address[] memory b = new address[](3);
        b[1] = e1;

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [address[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_AddressArray_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        address[] memory a = new address[](lenA);
        address[] memory b = new address[](lenB);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [address[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_AddressArray_Err_FailElements(address e1) external {
        vm.assume(e1 != address(0));

        address[] memory a = new address[](3);
        address[] memory b = new address[](3);
        b[1] = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_AddressArray_Err_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        address[] memory a = new address[](lenA);
        address[] memory b = new address[](lenB);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_AddressArray_Err_Pass(address e0, address e1, address e2) external {
        address[] memory a = new address[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        address[] memory b = new address[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertEq_AddressArray_Pass(address e0, address e1, address e2) external {
        address[] memory a = new address[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        address[] memory b = new address[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, EXPECT_PASS);
    }

    function test_AssertEq_BoolArray_FailElements() external {
        bool[] memory a = new bool[](1);
        bool[] memory b = new bool[](1);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bool[]]");
        a[0] = false;
        b[0] = true;
        prbTest._assertEq(a, b, EXPECT_FAIL);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bool[]]");
        a[0] = true;
        b[0] = false;
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_BoolArray_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        bool[] memory a = new bool[](lenA);
        bool[] memory b = new bool[](lenB);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bool[]]");
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_BoolArray_Err_FailElements() external {
        bool[] memory a = new bool[](1);
        bool[] memory b = new bool[](1);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        a[0] = false;
        b[0] = true;
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        a[0] = true;
        b[0] = false;
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_BoolArray_Err_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        bool[] memory a = new bool[](lenA);
        bool[] memory b = new bool[](lenB);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_BoolArray_Pass() external {
        bool[] memory a = new bool[](1);
        bool[] memory b = new bool[](1);

        a[0] = false;
        b[0] = false;
        prbTest._assertEq(a, b, EXPECT_PASS);

        a[0] = true;
        b[0] = true;
        prbTest._assertEq(a, b, EXPECT_PASS);
    }

    function test_AssertEq_BoolArray_Err_Pass() external {
        bool[] memory a = new bool[](1);
        bool[] memory b = new bool[](1);

        a[0] = false;
        b[0] = false;
        prbTest._assertEq(a, b, ERR, EXPECT_PASS);

        a[0] = true;
        b[0] = true;
        prbTest._assertEq(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Bytes32Array_FailElements(bytes32 e1) external {
        vm.assume(e1 != bytes32(uint256(0x00)));

        bytes32[] memory a = new bytes32[](3);
        bytes32[] memory b = new bytes32[](3);
        b[1] = e1;

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bytes32[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes32Array_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        bytes32[] memory a = new bytes32[](lenA);
        bytes32[] memory b = new bytes32[](lenB);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [bytes32[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes32Array_Err_FailElements(bytes32 e1) external {
        vm.assume(e1 != bytes32(uint256(0x00)));

        bytes32[] memory a = new bytes32[](3);
        bytes32[] memory b = new bytes32[](3);
        b[1] = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes32Array_Err_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        bytes32[] memory a = new bytes32[](lenA);
        bytes32[] memory b = new bytes32[](lenB);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Bytes32Array_Err_Pass(bytes32 e0, bytes32 e1, bytes32 e2) external {
        bytes32[] memory a = new bytes32[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        bytes32[] memory b = new bytes32[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Bytes32Array_Pass(bytes32 e0, bytes32 e1, bytes32 e2) external {
        bytes32[] memory a = new bytes32[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        bytes32[] memory b = new bytes32[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, EXPECT_PASS);
    }

    function test_AssertEq_Int256Array_FailElements(int256 e1) external {
        vm.assume(e1 != 0);

        int256[] memory a = new int256[](3);
        int256[] memory b = new int256[](3);
        b[1] = e1;

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [int256[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Int256Array_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        int256[] memory a = new int256[](lenA);
        int256[] memory b = new int256[](lenB);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [int256[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Int256Array_Err_FailElements(int256 e1) external {
        vm.assume(e1 != 0);

        int256[] memory a = new int256[](3);
        int256[] memory b = new int256[](3);
        b[1] = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Int256Array_Err_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        int256[] memory a = new int256[](lenA);
        int256[] memory b = new int256[](lenB);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Int256Array_Err_Pass(int256 e0, int256 e1, int256 e2) external {
        int256[] memory a = new int256[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        int256[] memory b = new int256[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Int256Array_Pass(int256 e0, int256 e1, int256 e2) external {
        int256[] memory a = new int256[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        int256[] memory b = new int256[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, EXPECT_PASS);
    }

    function test_AssertEq_StringArray_FailElements(string memory e1) external {
        vm.assume(!Helpers.eq(e1, ""));

        string[] memory a = new string[](3);
        string[] memory b = new string[](3);
        b[1] = e1;
        vm.expectEmit();
        emit Log("Error: a == b not satisfied [string[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_StringArray_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        string[] memory a = new string[](lenA);
        string[] memory b = new string[](lenB);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [string[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_StringArray_Err_FailElements(string memory e1) external {
        vm.assume(!Helpers.eq(e1, ""));

        string[] memory a = new string[](3);
        string[] memory b = new string[](3);
        b[1] = e1;
        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_StringArray_Err_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        string[] memory a = new string[](lenA);
        string[] memory b = new string[](lenB);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_StringArray_Err_Pass(string memory e0, string memory e1, string memory e2) external {
        string[] memory a = new string[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        string[] memory b = new string[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertEq_StringArray_Pass(string memory e0, string memory e1, string memory e2) external {
        string[] memory a = new string[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        string[] memory b = new string[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;
        prbTest._assertEq(a, b, EXPECT_PASS);
    }

    function test_AssertEq_Uint256Array_FailElements(uint256 e1) external {
        vm.assume(e1 != 0);

        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](3);
        b[1] = e1;

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [uint256[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Uint256Array_FailLengths(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        uint256[] memory a = new uint256[](lenA);
        uint256[] memory b = new uint256[](lenB);

        vm.expectEmit();
        emit Log("Error: a == b not satisfied [uint256[]]");
        prbTest._assertEq(a, b, EXPECT_FAIL);
    }

    function test_AssertEq_Uint256Array_Err_FailElements(uint256 e1) external {
        vm.assume(e1 != 0);

        uint256[] memory a = new uint256[](3);
        uint256[] memory b = new uint256[](3);
        b[1] = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Uint256Array_Err_FailElements(uint256 lenA, uint256 lenB) external {
        vm.assume(lenA != lenB);
        vm.assume(lenA <= 10_000);
        vm.assume(lenB <= 10_000);

        uint256[] memory a = new uint256[](lenA);
        uint256[] memory b = new uint256[](lenB);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertEq(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertEq_Uint256Array_Err_Pass(uint256 e0, uint256 e1, uint256 e2) external {
        uint256[] memory a = new uint256[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        uint256[] memory b = new uint256[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertEq_Uint256Array_Pass(uint256 e0, uint256 e1, uint256 e2) external {
        uint256[] memory a = new uint256[](3);
        a[0] = e0;
        a[1] = e1;
        a[2] = e2;

        uint256[] memory b = new uint256[](3);
        b[0] = e0;
        b[1] = e1;
        b[2] = e2;

        prbTest._assertEq(a, b, EXPECT_PASS);
    }
}
