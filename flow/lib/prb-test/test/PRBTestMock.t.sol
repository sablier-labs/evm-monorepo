// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { PRBTest } from "../src/PRBTest.sol";

contract PRBTestMock is PRBTest {
    /*//////////////////////////////////////////////////////////////////////////
                                FAILURE SYSTEM
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The HEVM will think that the test failed if it sees "failed" set to "0x01" at the end of the test.
    /// But because we're testing test assertions, "failed" being set to "0x01" might mean that our test passed.
    /// We need to set it back to "0x00".
    ///
    /// See https://github.com/dapphub/ds-test/pull/30.
    modifier expectFailure(bool expectFail) {
        // Load the previous state of the "failed" slot.
        bool preFailed = vm.load(VM_ADDRESS, bytes32("failed")) == bytes32(uint256(0x01));

        // The body of the function using this modifier is inserted here.
        _;

        // If the state of the DSTest contract was failed even before running this test, stop here.
        if (preFailed) {
            return;
        }

        // Load the current state of the "failed" slot.
        bool postFailed = vm.load(VM_ADDRESS, bytes32("failed")) == bytes32(uint256(0x01));

        // If the test expected the assertion to fail, then check if it did.
        if (expectFail) {
            require(postFailed, "expected failure not triggered");

            // Unwind the expected failure so that the test passes.
            vm.store(VM_ADDRESS, bytes32("failed"), bytes32(0x00));
        } else {
            require(!postFailed, "unexpected failure was triggered");
        }
    }

    function _fail() external expectFailure(true) {
        fail();
    }

    function _fail(string memory err) external expectFailure(true) {
        fail(err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                BOOLEAN ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _assertFalse(bool condition, bool expectFail) external expectFailure(expectFail) {
        assertFalse(condition);
    }

    function _assertFalse(bool condition, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertFalse(condition, err);
    }

    function _assertTrue(bool condition, bool expectFail) external expectFailure(expectFail) {
        assertTrue(condition);
    }

    function _assertTrue(bool condition, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertTrue(condition, err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                EQUALITY ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _assertEq(address a, address b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(address a, address b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b, err);
    }

    function _assertEq(address[] memory a, address[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        address[] memory a,
        address[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(bool a, bool b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(bool a, bool b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b, err);
    }

    function _assertEq(bool[] memory a, bool[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        bool[] memory a,
        bool[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(bytes memory a, bytes memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        bytes memory a,
        bytes memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(bytes32 a, bytes32 b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(bytes32 a, bytes32 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b, err);
    }

    function _assertEq(bytes32[] memory a, bytes32[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        bytes32[] memory a,
        bytes32[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(int256 a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(int256 a, int256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b, err);
    }

    function _assertEq(int256[] memory a, int256[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        int256[] memory a,
        int256[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(string memory a, string memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        string memory a,
        string memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(string[] memory a, string[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        string[] memory a,
        string[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    function _assertEq(uint256 a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(uint256 a, uint256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b, err);
    }

    function _assertEq(uint256[] memory a, uint256[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertEq(a, b);
    }

    function _assertEq(
        uint256[] memory a,
        uint256[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertEq(a, b, err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INEQUALITY ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _assertNotEq(address a, address b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        address a,
        address b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(address[] memory a, address[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        address[] memory a,
        address[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(bool a, bool b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(bool a, bool b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(bool[] memory a, bool[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        bool[] memory a,
        bool[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(bytes memory a, bytes memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        bytes memory a,
        bytes memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(bytes32 a, bytes32 b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        bytes32 a,
        bytes32 b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(bytes32[] memory a, bytes32[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        bytes32[] memory a,
        bytes32[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(int256 a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(int256 a, int256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(int256[] memory a, int256[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        int256[] memory a,
        int256[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(string memory a, string memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        string memory a,
        string memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(string[] memory a, string[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        string[] memory a,
        string[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(uint256 a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        uint256 a,
        uint256 b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    function _assertNotEq(uint256[] memory a, uint256[] memory b, bool expectFail) external expectFailure(expectFail) {
        assertNotEq(a, b);
    }

    function _assertNotEq(
        uint256[] memory a,
        uint256[] memory b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertNotEq(a, b, err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                APPROXIMATE ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _assertAlmostEq(
        int256 a,
        int256 b,
        uint256 maxDelta,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertAlmostEq(a, b, maxDelta);
    }

    function _assertAlmostEq(
        int256 a,
        int256 b,
        uint256 maxDelta,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertAlmostEq(a, b, maxDelta, err);
    }

    function _assertAlmostEq(
        uint256 a,
        uint256 b,
        uint256 maxDelta,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertAlmostEq(a, b, maxDelta);
    }

    function _assertAlmostEq(
        uint256 a,
        uint256 b,
        uint256 maxDelta,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertAlmostEq(a, b, maxDelta, err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NUMERICAL COMPARISON ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _assertGt(int256 a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertGt(a, b);
    }

    function _assertGt(int256 a, int256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertGt(a, b, err);
    }

    function _assertGt(uint256 a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertGt(a, b);
    }

    function _assertGt(uint256 a, uint256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertGt(a, b, err);
    }

    function _assertGte(int256 a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertGte(a, b);
    }

    function _assertGte(int256 a, int256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertGte(a, b, err);
    }

    function _assertGte(uint256 a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertGte(a, b);
    }

    function _assertGte(uint256 a, uint256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertGte(a, b, err);
    }

    function _assertLt(int256 a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertLt(a, b);
    }

    function _assertLt(int256 a, int256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertLt(a, b, err);
    }

    function _assertLt(uint256 a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertLt(a, b);
    }

    function _assertLt(uint256 a, uint256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertLt(a, b, err);
    }

    function _assertLte(int256 a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertLte(a, b);
    }

    function _assertLte(int256 a, int256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertLte(a, b, err);
    }

    function _assertLte(uint256 a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertLte(a, b);
    }

    function _assertLte(uint256 a, uint256 b, string memory err, bool expectFail) external expectFailure(expectFail) {
        assertLte(a, b, err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONTAINMENT ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _assertContains(address[] memory a, address b, bool expectFail) external expectFailure(expectFail) {
        assertContains(a, b);
    }

    function _assertContains(
        address[] memory a,
        address b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertContains(a, b, err);
    }

    function _assertContains(bytes32[] memory a, bytes32 b, bool expectFail) external expectFailure(expectFail) {
        assertContains(a, b);
    }

    function _assertContains(
        bytes32[] memory a,
        bytes32 b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertContains(a, b, err);
    }

    function _assertContains(int256[] memory a, int256 b, bool expectFail) external expectFailure(expectFail) {
        assertContains(a, b);
    }

    function _assertContains(
        int256[] memory a,
        int256 b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertContains(a, b, err);
    }

    function _assertContains(uint256[] memory a, uint256 b, bool expectFail) external expectFailure(expectFail) {
        assertContains(a, b);
    }

    function _assertContains(
        uint256[] memory a,
        uint256 b,
        string memory err,
        bool expectFail
    )
        external
        expectFailure(expectFail)
    {
        assertContains(a, b, err);
    }
}
