// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";

import { Amounts, LinearStream, ProStream, Range, Segment } from "src/types/Structs.sol";

abstract contract Assertions is PRBTest, PRBMathAssertions {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    event LogNamedArray(string key, SD1x18[] value);

    event LogNamedArray(string key, uint40[] value);

    event LogNamedArray(string key, uint128[] value);

    event LogNamedArray(string key, Segment[] segments);

    event LogNamedUint128(string key, uint128 value);

    event LogNamedUint40(string key, uint40 value);

    /*//////////////////////////////////////////////////////////////////////////
                                     ASSERTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that the given stream was deleted.
    function assertDeleted(uint256 streamId) internal virtual;

    /// @dev Checks that the given streams were deleted.
    function assertDeleted(uint256[] memory streamIds) internal virtual;

    /// @dev Compares two `Amounts` struct entities.
    function assertEq(Amounts memory a, Amounts memory b) internal {
        assertEqUint128(a.deposit, b.deposit);
        assertEqUint128(a.withdrawn, b.withdrawn);
    }

    /// @dev Compares two `IERC20` addresses.
    function assertEq(IERC20 a, IERC20 b) internal {
        assertEq(address(a), address(b));
    }

    /// @dev Compares two `LinearStream` struct entities.
    function assertEq(LinearStream memory a, LinearStream memory b) internal {
        assertEq(a.amounts, b.amounts);
        assertEq(a.isCancelable, b.isCancelable);
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.sender, b.sender);
        assertEq(a.range, b.range);
        assertEq(a.token, b.token);
    }

    /// @dev Compares two `ProStream` struct entities.
    function assertEq(ProStream memory a, ProStream memory b) internal {
        assertEq(a.isCancelable, b.isCancelable);
        assertEq(a.isEntity, b.isEntity);
        assertEq(a.segments, b.segments);
        assertEq(a.sender, b.sender);
        assertEq(a.startTime, b.startTime);
        assertEq(a.token, b.token);
    }

    /// @dev Compares two `Segment[]` arrays.
    function assertEq(Segment[] memory a, Segment[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [Segment[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Compares two `Range` struct entities.
    function assertEq(Range memory a, Range memory b) internal {
        assertEqUint40(a.cliff, b.cliff);
        assertEqUint40(a.start, b.start);
        assertEqUint40(a.stop, b.stop);
    }

    /// @dev Compares two `uint128` numbers.
    function assertEqUint128(uint128 a, uint128 b) internal {
        if (a != b) {
            emit Log("Error: a == b not satisfied [uint128]");
            emit LogNamedUint128("  Expected", b);
            emit LogNamedUint128("    Actual", a);
            fail();
        }
    }

    /// @dev Compares two `uint128` arrays.
    function assertEqUint128Array(uint128[] memory a, uint128[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint128[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }

    /// @dev Compares two `uint40` numbers.
    function assertEqUint40(uint40 a, uint40 b) internal {
        if (a != b) {
            emit Log("Error: a == b not satisfied [uint40]");
            emit LogNamedUint40("  Expected", b);
            emit LogNamedUint40("    Actual", a);
            fail();
        }
    }

    /// @dev Compares two `uint40` arrays.
    function assertEqUint40Array(uint40[] memory a, uint40[] memory b) internal {
        if (keccak256(abi.encode(a)) != keccak256(abi.encode(b))) {
            emit Log("Error: a == b not satisfied [uint40[]]");
            emit LogNamedArray("  Expected", b);
            emit LogNamedArray("    Actual", a);
            fail();
        }
    }
}
