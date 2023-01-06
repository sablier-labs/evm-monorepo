// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

abstract contract Utils is StdUtils, PRBMathUtils {
    /// @dev Bound a `uint128` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal view returns (uint128 result) {
        result = uint128(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Bound a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal view returns (uint40 result) {
        result = uint40(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Convert a `uint128` number to the `SD59x18` format. The casting is safe because the domain of the
    /// `int256` type is larger than the domain of the `uint128` type.
    function sdUint128(uint128 x) internal pure returns (SD59x18 result) {
        result = SD59x18.wrap(int256(uint256(x)));
    }

    /// @dev Convert a `uint40` number to the `SD59x18` format. The casting is safe because the domain of the
    /// `int256` type is larger than the domain of the `uint40` type.
    function sdUint40(uint40 x) internal pure returns (SD59x18 result) {
        result = SD59x18.wrap(int256(uint256(x)));
    }
}
