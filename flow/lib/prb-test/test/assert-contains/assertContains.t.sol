// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest_Test } from "../PRBTest.t.sol";

contract AssertContains_Test is PRBTest_Test {
    function test_AssertContains_Address_Fail(address e0, address e1) external {
        vm.assume(e0 != e1);

        address[] memory a = new address[](1);
        a[0] = e0;
        address b = e1;

        vm.expectEmit();
        emit Log("Error: a does not contain b [address[]]");
        prbTest._assertContains(a, b, EXPECT_FAIL);
    }

    function test_AssertContains_Address_Err_Fail(address e0, address e1) external {
        vm.assume(e0 != e1);

        address[] memory a = new address[](1);
        a[0] = e0;
        address b = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertContains(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertContains_Address_Err_Pass(address e0, address e1) external {
        vm.assume(e0 != address(0));

        address[] memory a = new address[](2);
        a[0] = e0;
        a[1] = e1;
        address b = e1;
        prbTest._assertContains(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertContains_Address_Pass(address e0, address e1) external {
        vm.assume(e0 != address(0));

        address[] memory a = new address[](2);
        a[0] = e0;
        a[1] = e1;
        address b = e1;
        prbTest._assertContains(a, b, EXPECT_PASS);
    }

    function test_AssertContains_Bytes32_Fail(bytes32 e0, bytes32 e1) external {
        vm.assume(e0 != e1);

        bytes32[] memory a = new bytes32[](1);
        a[0] = e0;
        bytes32 b = e1;

        vm.expectEmit();
        emit Log("Error: a does not contain b [bytes32[]]");
        prbTest._assertContains(a, b, EXPECT_FAIL);
    }

    function test_AssertContains_Bytes32_Err_Fail(bytes32 e0, bytes32 e1) external {
        vm.assume(e0 != e1);

        bytes32[] memory a = new bytes32[](1);
        a[0] = e0;
        bytes32 b = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertContains(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertContains_Bytes32_Err_Pass(bytes32 e0, bytes32 e1) external {
        vm.assume(e0 != bytes32(uint256(0x00)));

        bytes32[] memory a = new bytes32[](2);
        a[0] = e0;
        a[1] = e1;
        bytes32 b = e1;
        prbTest._assertContains(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertContains_Bytes32_Pass(bytes32 e0, bytes32 e1) external {
        vm.assume(e0 != bytes32(uint256(0x00)));

        bytes32[] memory a = new bytes32[](2);
        a[0] = e0;
        a[1] = e1;
        bytes32 b = e1;
        prbTest._assertContains(a, b, EXPECT_PASS);
    }

    function test_AssertContains_Int256_Fail(int256 e0, int256 e1) external {
        vm.assume(e0 != e1);

        int256[] memory a = new int256[](1);
        a[0] = e0;
        int256 b = e1;

        vm.expectEmit();
        emit Log("Error: a does not contain b [int256[]]");
        prbTest._assertContains(a, b, EXPECT_FAIL);
    }

    function test_AssertContains_Int256_Err_Fail(int256 e0, int256 e1) external {
        vm.assume(e0 != e1);

        int256[] memory a = new int256[](1);
        a[0] = e0;
        int256 b = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertContains(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertContains_Int256_Err_Pass(int256 e0, int256 e1) external {
        vm.assume(e0 != 0);

        int256[] memory a = new int256[](2);
        a[0] = e0;
        a[1] = e1;
        int256 b = e1;
        prbTest._assertContains(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertContains_Int256_Pass(int256 e0, int256 e1) external {
        vm.assume(e0 != 0);

        int256[] memory a = new int256[](2);
        a[0] = e0;
        a[1] = e1;
        int256 b = e1;
        prbTest._assertContains(a, b, EXPECT_PASS);
    }

    function test_AssertContains_Uint256_Fail(uint256 e0, uint256 e1) external {
        vm.assume(e0 != e1);

        uint256[] memory a = new uint256[](1);
        a[0] = e0;
        uint256 b = e1;

        vm.expectEmit();
        emit Log("Error: a does not contain b [uint256[]]");
        prbTest._assertContains(a, b, EXPECT_FAIL);
    }

    function test_AssertContains_Uint256_Err_Fail(uint256 e0, uint256 e1) external {
        vm.assume(e0 != e1);

        uint256[] memory a = new uint256[](1);
        a[0] = e0;
        uint256 b = e1;

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertContains(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertContains_Uint256_Err_Pass(uint256 e0, uint256 e1) external {
        vm.assume(e0 != 0);

        uint256[] memory a = new uint256[](2);
        a[0] = e0;
        a[1] = e1;
        uint256 b = e1;
        prbTest._assertContains(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertContains_Uint256_Pass(uint256 e0, uint256 e1) external {
        vm.assume(e0 != 0);

        uint256[] memory a = new uint256[](2);
        a[0] = e0;
        a[1] = e1;
        uint256 b = e1;
        prbTest._assertContains(a, b, EXPECT_PASS);
    }
}
