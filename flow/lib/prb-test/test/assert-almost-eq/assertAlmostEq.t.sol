// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import "../../src/Helpers.sol" as Helpers;

import { PRBTest_Test } from "../PRBTest.t.sol";

contract AssertAlmostEq_Test is PRBTest_Test {
    function test_AssertAlmostEq_Int256_Fail(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) > maxDelta);

        vm.expectEmit();
        emit Log("Error: a ~= b not satisfied [int256]");
        prbTest._assertAlmostEq(a, b, maxDelta, EXPECT_FAIL);
    }

    function test_AssertAlmostEq_Int256_Err_Fail(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) > maxDelta);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertAlmostEq(a, b, maxDelta, ERR, EXPECT_FAIL);
    }

    function test_AssertAlmostEq_Int256_Err_Pass(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) <= maxDelta);
        prbTest._assertAlmostEq(a, b, maxDelta, ERR, EXPECT_PASS);
    }

    function test_AssertAlmostEq_Int256_Pass(int256 a, int256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) <= maxDelta);
        prbTest._assertAlmostEq(a, b, maxDelta, EXPECT_PASS);
    }

    function test_AssertAlmostEq_Uint256_Fail(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) > maxDelta);

        vm.expectEmit();
        emit Log("Error: a ~= b not satisfied [uint256]");
        prbTest._assertAlmostEq(a, b, maxDelta, EXPECT_FAIL);
    }

    function test_AssertAlmostEq_Uint256_Err_Fail(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) > maxDelta);

        vm.expectEmit();
        emit LogNamedString("Error", ERR);
        prbTest._assertAlmostEq(a, b, maxDelta, ERR, EXPECT_FAIL);
    }

    function test_AssertAlmostEq_Uint256_Err_Pass(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) <= maxDelta);
        prbTest._assertAlmostEq(a, b, maxDelta, ERR, EXPECT_PASS);
    }

    function test_AssertAlmostEq_Uint256_Pass(uint256 a, uint256 b, uint256 maxDelta) external {
        vm.assume(Helpers.delta(a, b) <= maxDelta);
        prbTest._assertAlmostEq(a, b, maxDelta, EXPECT_PASS);
    }
}
