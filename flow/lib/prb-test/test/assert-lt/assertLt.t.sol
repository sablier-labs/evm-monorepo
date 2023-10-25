// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest_Test } from "../PRBTest.t.sol";

contract AssertLt_Test is PRBTest_Test {
    function test_AssertLt_Fail(int256 a, int256 b) external {
        vm.assume(a >= b);

        vm.expectEmit();
        emit Log("Error: a < b not satisfied [int256]");
        prbTest._assertLt(a, b, EXPECT_FAIL);
    }

    function test_AssertLt_Err_Fail(int256 a, int256 b) external {
        vm.assume(a >= b);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertLt(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertLt_Err_Pass(int256 a, int256 b) external {
        vm.assume(a < b);

        prbTest._assertLt(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertLt_Pass(int256 a, int256 b) external {
        vm.assume(a < b);

        prbTest._assertLt(a, b, EXPECT_PASS);
    }

    function test_AssertLt_Fail(uint256 a, uint256 b) external {
        vm.assume(a >= b);

        vm.expectEmit();
        emit Log("Error: a < b not satisfied [uint256]");
        prbTest._assertLt(a, b, EXPECT_FAIL);
    }

    function test_AssertLt_Err_Fail(uint256 a, uint256 b) external {
        vm.assume(a >= b);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertLt(a, b, ERR, EXPECT_FAIL);
    }

    function test_AssertLt_Err_Pass(uint256 a, uint256 b) external {
        vm.assume(a < b);

        prbTest._assertLt(a, b, ERR, EXPECT_PASS);
    }

    function test_AssertLt_Pass(uint256 a, uint256 b) external {
        vm.assume(a < b);

        prbTest._assertLt(a, b, EXPECT_PASS);
    }
}
