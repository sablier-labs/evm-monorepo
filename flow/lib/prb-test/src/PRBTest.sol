// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Helpers.sol" as Helpers;
import { Vm } from "./Vm.sol";

/*

██████╗ ██████╗ ██████╗ ████████╗███████╗███████╗████████╗
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝
██████╔╝██████╔╝██████╔╝   ██║   █████╗  ███████╗   ██║
██╔═══╝ ██╔══██╗██╔══██╗   ██║   ██╔══╝  ╚════██║   ██║
██║     ██║  ██║██████╔╝   ██║   ███████╗███████║   ██║
╚═╝     ╚═╝  ╚═╝╚═════╝    ╚═╝   ╚══════╝╚══════╝   ╚═╝

*/

/// @notice Modern collection of testing assertions and logging utilities.
/// @author Paul Razvan Berg
/// @dev Inspired by DSTest.
contract PRBTest {
    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/
    event Log(string err);
    event LogAddress(address value);
    event LogArray(address[] value);
    event LogArray(bool[] value);
    event LogArray(bytes32[] value);
    event LogArray(int256[] value);
    event LogArray(string[] value);
    event LogArray(uint256[] value);
    event LogBytes(bytes value);
    event LogBytes32(bytes32 value);
    event LogString(string value);
    event LogInt256(int256 value);
    event LogUint256(uint256 value);
    event LogNamedAddress(string key, address value);
    event LogNamedArray(string key, address[] value);
    event LogNamedArray(string key, bool[] value);
    event LogNamedArray(string key, bytes32[] value);
    event LogNamedArray(string key, int256[] value);
    event LogNamedArray(string key, string[] value);
    event LogNamedArray(string key, uint256[] value);
    event LogNamedBytes(string key, bytes value);
    event LogNamedBytes32(string key, bytes32 value);
    event LogNamedInt256(string key, int256 value);
    event LogNamedString(string key, string value);
    event LogNamedUint256(string key, uint256 value);

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A flag to indicate that this is a test contract.
    function IS_TEST() external pure virtual returns (bool) {
        return true;
    }

    /// @dev The maximum value available in the int256 type.
    int256 internal constant MAX_INT256 = type(int256).max;

    /// @dev The maximum value available in the uint256 type.
    uint256 internal constant MAX_UINT256 = type(uint256).max;

    /// @dev The minimum value available in the int256 type.
    int256 internal constant MIN_INT256 = type(int256).min;

    /*//////////////////////////////////////////////////////////////////////////
                                    CHEATCODES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The virtual address of the Foundry VM.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));

    /// @dev An instance of the Foundry VM, which contains cheatcodes for testing.
    Vm internal constant vm = Vm(VM_ADDRESS);

    /*//////////////////////////////////////////////////////////////////////////
                                FAILURE SYSTEM
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev This instance's failure flag.
    bool private _failed;

    /// @dev Checks whether any test has failed so far. In addition to the local failure flag, we look for the global
    /// flag in the HEVM contract at storage slot "failed", because it is possible to run assertions between different
    /// instances of PRBTest.
    /// See https://github.com/dapphub/dapptools/issues/768.
    function failed() public returns (bool) {
        if (_failed) {
            return true;
        }

        // If there is HEVM context, load the global variable "failed".
        if (VM_ADDRESS.code.length > 0) {
            (, bytes memory returndata) = VM_ADDRESS.call(
                abi.encodePacked(bytes4(keccak256("load(address,bytes32)")), abi.encode(VM_ADDRESS, bytes32("failed")))
            );
            bool globalFailed = abi.decode(returndata, (bool));
            return globalFailed;
        } else {
            return false;
        }
    }

    /// @dev Fails the test by setting the private variable `_failed` to `true` and storing "0x01" at the "failed"
    /// storage slot on the HEVM contract. Doing this instead of reverting makes it possible to test multiple
    /// assertions in one test function while also preserving emitted events.
    function fail() internal {
        // If there is no HEVM context, stop here.
        if (VM_ADDRESS.code.length == 0) {
            return;
        }

        // Store "0x01" at the "failed" storage slot on the HEVM contract.
        (bool status,) = VM_ADDRESS.call(
            abi.encodePacked(
                bytes4(keccak256("store(address,bytes32,bytes32)")),
                abi.encode(VM_ADDRESS, bytes32("failed"), bytes32(uint256(0x01)))
            )
        );

        // Dummy statement to silence the compiler warning.
        status;

        // Set this instance's failed flag to `true`.
        _failed = true;
    }

    /// @dev Logs the error message `err` and fails the test.
    function fail(string memory err) internal {
        emit LogNamedString("Error", err);
        fail();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                BOOLEAN ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `condition` evaluates to `true`. If it does not, the test fails.
    function assertTrue(bool condition) internal virtual {
        if (!condition) {
            emit Log("Error: Assertion Failed");
            fail();
        }
    }

    /// @dev Tests that `condition` evaluates to `true`. If it does not, the test fails with the error message `err`.
    function assertTrue(bool condition, string memory err) internal virtual {
        if (!condition) {
            emit LogNamedString("Error", err);
            fail();
        }
    }

    /// @dev Tests that `condition` evaluates to `false`. If it does not, the test fails.
    function assertFalse(bool condition) internal virtual {
        assertTrue(!condition);
    }

    /// @dev Tests that `condition` evaluates to `false`. If it does not, the test fails with the error message `err`.
    function assertFalse(bool condition, string memory err) internal virtual {
        assertTrue(!condition, err);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                EQUALITY ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    function assertEq(address a, address b) internal virtual {
        if (a != b) {
            emit Log("Error: a == b not satisfied [address]");
            emit LogNamedAddress("   Left", a);
            emit LogNamedAddress("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    function assertEq(address a, address b, string memory err) internal virtual {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(address[] memory a, address[] memory b) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [address[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(address[] memory a, address[] memory b, string memory err) internal virtual {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    function assertEq(bool a, bool b) internal virtual {
        if (a != b) {
            emit Log("Error: a == b not satisfied [bool]");
            emit LogNamedString("   Left", a ? "true" : "false");
            emit LogNamedString("  Right", b ? "true" : "false");
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    function assertEq(bool a, bool b, string memory err) internal virtual {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(bool[] memory a, bool[] memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [bool[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(bool[] memory a, bool[] memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(bytes memory a, bytes memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [bytes]");
            emit LogNamedBytes("   Left", a);
            emit LogNamedBytes("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(bytes memory a, bytes memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    function assertEq(bytes32 a, bytes32 b) internal virtual {
        if (a != b) {
            emit Log("Error: a == b not satisfied [bytes32]");
            emit LogNamedBytes32("   Left", a);
            emit LogNamedBytes32("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    function assertEq(bytes32 a, bytes32 b, string memory err) internal virtual {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(bytes32[] memory a, bytes32[] memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [bytes32[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(bytes32[] memory a, bytes32[] memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal.
    function assertEq(int256 a, int256 b) internal virtual {
        if (a != b) {
            emit Log("Error: a == b not satisfied [int256]");
            emit LogNamedInt256("   Left", a);
            emit LogNamedInt256("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    function assertEq(int256 a, int256 b, string memory err) internal virtual {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(int256[] memory a, int256[] memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [int256[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(int256[] memory a, int256[] memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the strings, which is faster than iterating over the elements.
    function assertEq(string memory a, string memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [string]");
            emit LogNamedString("   Left", a);
            emit LogNamedString("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the strings, which is faster than iterating over the elements.
    function assertEq(string memory a, string memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(string[] memory a, string[] memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [string[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(string[] memory a, string[] memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    function assertEq(uint256 a, uint256 b) internal virtual {
        if (a != b) {
            emit Log("Error: a == b not satisfied [uint256]");
            emit LogNamedUint256("   Left", a);
            emit LogNamedUint256("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    function assertEq(uint256 a, uint256 b, string memory err) internal virtual {
        if (a != b) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(uint256[] memory a, uint256[] memory b) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit Log("Error: a == b not satisfied [uint256[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertEq(uint256[] memory a, uint256[] memory b, string memory err) internal virtual {
        if (!Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertEq(a, b);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INEQUALITY ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    function assertNotEq(address a, address b) internal virtual {
        if (a == b) {
            emit Log("Error: a != b not satisfied [address]");
            emit LogNamedAddress("   Left", a);
            emit LogNamedAddress("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    function assertNotEq(address a, address b, string memory err) internal virtual {
        if (a == b) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(address[] memory a, address[] memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [address[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(address[] memory a, address[] memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    function assertNotEq(bool a, bool b) internal virtual {
        if (a == b) {
            emit Log("Error: a != b not satisfied [bool]");
            emit LogNamedString("   Left", a ? "true" : "false");
            emit LogNamedString("  Right", b ? "true" : "false");
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    function assertNotEq(bool a, bool b, string memory err) internal virtual {
        if (a == b) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(bool[] memory a, bool[] memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [bool[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(bool[] memory a, bool[] memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(bytes memory a, bytes memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [bytes]");
            emit LogNamedBytes("   Left", a);
            emit LogNamedBytes("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are equal. If they are not, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(bytes memory a, bytes memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    function assertNotEq(bytes32 a, bytes32 b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [bytes32]");
            emit LogNamedBytes32("   Left", a);
            emit LogNamedBytes32("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    function assertNotEq(bytes32 a, bytes32 b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(bytes32[] memory a, bytes32[] memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [bytes32[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(bytes32[] memory a, bytes32[] memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    function assertNotEq(int256 a, int256 b) internal virtual {
        if (a == b) {
            emit Log("Error: a != b not satisfied [int256]");
            emit LogNamedInt256("   Left", a);
            emit LogNamedInt256("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    function assertNotEq(int256 a, int256 b, string memory err) internal virtual {
        if (a == b) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(int256[] memory a, int256[] memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [int256[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(int256[] memory a, int256[] memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the strings, which is faster than iterating over the elements.
    function assertNotEq(string memory a, string memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [string]");
            emit LogNamedString("   Left", a);
            emit LogNamedString("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the strings, which is faster than iterating over the elements.
    function assertNotEq(string memory a, string memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(string[] memory a, string[] memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [string[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(string[] memory a, string[] memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    function assertNotEq(uint256 a, uint256 b) internal virtual {
        if (a == b) {
            emit Log("Error: a != b not satisfied [uint256]");
            emit LogNamedUint256("   Left", a);
            emit LogNamedUint256("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    function assertNotEq(uint256 a, uint256 b, string memory err) internal virtual {
        if (a == b) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(uint256[] memory a, uint256[] memory b) internal virtual {
        if (Helpers.eq(a, b)) {
            emit Log("Error: a != b not satisfied [uint256[]]");
            emit LogNamedArray("   Left", a);
            emit LogNamedArray("  Right", b);
            fail();
        }
    }

    /// @dev Tests that `a` and `b` are not equal. If they are, the test fails with the error message `err`.
    /// Works by comparing the `keccak256` hashes of the arrays, which is faster than iterating over the elements.
    function assertNotEq(uint256[] memory a, uint256[] memory b, string memory err) internal virtual {
        if (Helpers.eq(a, b)) {
            emit LogNamedString("Error", err);
            assertNotEq(a, b);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                APPROXIMATE ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that the absolute difference between `a and `b` is less than or equal to `maxDelta`.
    /// If it is not, the test fails.
    function assertAlmostEq(int256 a, int256 b, uint256 maxDelta) internal virtual {
        uint256 actualDelta = Helpers.delta(a, b);
        if (actualDelta > maxDelta) {
            emit Log("Error: a ~= b not satisfied [int256]");
            emit LogNamedInt256("      Expected", b);
            emit LogNamedInt256("      Right", a);
            emit LogNamedUint256("     Max Delta", maxDelta);
            emit LogNamedUint256("  Actual Delta", actualDelta);
            fail();
        }
    }

    /// @dev Tests that the absolute difference between `a and `b` is less than or equal to `maxDelta`.
    /// If it is not, the test fails with the error message `err`.
    function assertAlmostEq(int256 a, int256 b, uint256 maxDelta, string memory err) internal virtual {
        if (Helpers.delta(a, b) > maxDelta) {
            emit LogNamedString("Error", err);
            assertAlmostEq(a, b, maxDelta);
        }
    }

    /// @dev Tests that the absolute difference between `a and `b` is less than or equal to `maxDelta`.
    /// If it is not, the test fails.
    function assertAlmostEq(uint256 a, uint256 b, uint256 maxDelta) internal virtual {
        uint256 actualDelta = Helpers.delta(a, b);
        if (actualDelta > maxDelta) {
            emit Log("Error: a ~= b not satisfied [uint256]");
            emit LogNamedUint256("      Expected", b);
            emit LogNamedUint256("      Right", a);
            emit LogNamedUint256("     Max Delta", maxDelta);
            emit LogNamedUint256("  Actual Delta", actualDelta);
            fail();
        }
    }

    /// @dev Tests that the absolute difference between `a and `b` is less than or equal to `maxDelta`.
    /// If it is not, the test fails with the error message `err`.
    function assertAlmostEq(uint256 a, uint256 b, uint256 maxDelta, string memory err) internal virtual {
        if (Helpers.delta(a, b) > maxDelta) {
            emit LogNamedString("Error", err);
            assertAlmostEq(a, b, maxDelta);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NUMERICAL COMPARISON ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `a` is greater than `b`. If it is not, the test fails.
    function assertGt(int256 a, int256 b) internal virtual {
        if (a <= b) {
            emit Log("Error: a > b not satisfied [int256]");
            emit LogNamedInt256("  Value a", a);
            emit LogNamedInt256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is greater than `b`. If it is not, the test fails with the error message `err`.
    function assertGt(int256 a, int256 b, string memory err) internal virtual {
        if (a <= b) {
            emit LogNamedString("Error", err);
            assertGt(a, b);
        }
    }

    /// @dev Tests that `a` is greater than `b`. If it is not, the test fails.
    function assertGt(uint256 a, uint256 b) internal virtual {
        if (a <= b) {
            emit Log("Error: a > b not satisfied [uint256]");
            emit LogNamedUint256("  Value a", a);
            emit LogNamedUint256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is greater than `b`. If it is not, the test fails with the error message `err`.
    function assertGt(uint256 a, uint256 b, string memory err) internal virtual {
        if (a <= b) {
            emit LogNamedString("Error", err);
            assertGt(a, b);
        }
    }

    /// @dev Tests that `a` is greater than or equal to `b`. If it is not, the test fails.
    function assertGte(int256 a, int256 b) internal virtual {
        if (a < b) {
            emit Log("Error: a >= b not satisfied [int256]");
            emit LogNamedInt256("  Value a", a);
            emit LogNamedInt256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is greater than or equal to `b`. If it is not, the test fails with the error message `err`.
    function assertGte(int256 a, int256 b, string memory err) internal virtual {
        if (a < b) {
            emit LogNamedString("Error", err);
            assertGte(a, b);
        }
    }

    /// @dev Tests that `a` is greater than or equal to `b`. If it is not, the test fails.
    function assertGte(uint256 a, uint256 b) internal virtual {
        if (a < b) {
            emit Log("Error: a >= b not satisfied [uint256]");
            emit LogNamedUint256("  Value a", a);
            emit LogNamedUint256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is greater than or equal to `b`. If it is not, the test fails with the error message `err`.
    function assertGte(uint256 a, uint256 b, string memory err) internal virtual {
        if (a < b) {
            emit LogNamedString("Error", err);
            assertGte(a, b);
        }
    }

    /// @dev Tests that `a` is lower than `b`. If it is not, the test fails.
    function assertLt(int256 a, int256 b) internal virtual {
        if (a >= b) {
            emit Log("Error: a < b not satisfied [int256]");
            emit LogNamedInt256("  Value a", a);
            emit LogNamedInt256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is lower than `b`. If it is not, the test fails with the error message `err`.
    function assertLt(int256 a, int256 b, string memory err) internal virtual {
        if (a >= b) {
            emit LogNamedString("Error", err);
            assertLt(a, b);
        }
    }

    /// @dev Tests that `a` is lower than `b`. If it is not, the test fails.
    function assertLt(uint256 a, uint256 b) internal virtual {
        if (a >= b) {
            emit Log("Error: a < b not satisfied [uint256]");
            emit LogNamedUint256("  Value a", a);
            emit LogNamedUint256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is lower than `b`. If it is not, the test fails with the error message `err`.
    function assertLt(uint256 a, uint256 b, string memory err) internal virtual {
        if (a >= b) {
            emit LogNamedString("Error", err);
            assertLt(a, b);
        }
    }

    /// @dev Tests that `a` is lower than or equal to `b`. If it is not, the test fails.
    function assertLte(int256 a, int256 b) internal virtual {
        if (a > b) {
            emit Log("Error: a <= b not satisfied [int256]");
            emit LogNamedInt256("  Value a", a);
            emit LogNamedInt256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is lower than or equal to `b`. If it is not, the test fails with the error message `err`.
    function assertLte(int256 a, int256 b, string memory err) internal virtual {
        if (a > b) {
            emit LogNamedString("Error", err);
            assertLte(a, b);
        }
    }

    /// @dev Tests that `a` is lower than or equal to `b`. If it is not, the test fails.
    function assertLte(uint256 a, uint256 b) internal virtual {
        if (a > b) {
            emit Log("Error: a <= b not satisfied [uint256]");
            emit LogNamedUint256("  Value a", a);
            emit LogNamedUint256("  Value b", b);
            fail();
        }
    }

    /// @dev Tests that `a` is lower than or equal to `b`. If it is not, the test fails with the error message `err`.
    function assertLte(uint256 a, uint256 b, string memory err) internal virtual {
        if (a > b) {
            emit LogNamedString("Error", err);
            assertLte(a, b);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CONTAINMENT ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Tests that `a` contains `b`. If it does not, the test fails.
    function assertContains(address[] memory a, address b) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit Log("Error: a does not contain b [address[]]");
            emit LogNamedArray("  Array a", a);
            emit LogNamedAddress("   Item b", b);
            fail();
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails with the error message `err`.
    function assertContains(address[] memory a, address b, string memory err) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails.
    function assertContains(bytes32[] memory a, bytes32 b) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit Log("Error: a does not contain b [bytes32[]]");
            emit LogNamedArray("  Array a", a);
            emit LogNamedBytes32("   Item b", b);
            fail();
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails with the error message `err`.
    function assertContains(bytes32[] memory a, bytes32 b, string memory err) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails.
    function assertContains(int256[] memory a, int256 b) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit Log("Error: a does not contain b [int256[]]");
            emit LogNamedArray("  Array a", a);
            emit LogNamedInt256("   Item b", b);
            fail();
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails with the error message `err`.
    function assertContains(int256[] memory a, int256 b, string memory err) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails.
    function assertContains(string[] memory a, string memory b) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit Log("Error: a does not contain b [string[]]");
            emit LogNamedArray("  Array a", a);
            emit LogNamedString("   Item b", b);
            fail();
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails with the error message `err`.
    function assertContains(string[] memory a, string memory b, string memory err) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails.
    function assertContains(uint256[] memory a, uint256 b) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit Log("Error: a does not contain b [uint256[]]");
            emit LogNamedArray("  Array a", a);
            emit LogNamedUint256("   Item b", b);
            fail();
        }
    }

    /// @dev Tests that `a` contains `b`. If it does not, the test fails with the error message `err`.
    function assertContains(uint256[] memory a, uint256 b, string memory err) internal virtual {
        if (!Helpers.contains(a, b)) {
            emit LogNamedString("Error", err);
            assertContains(a, b);
        }
    }
}
