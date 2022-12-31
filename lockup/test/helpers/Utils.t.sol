// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { PRBMathUtils } from "@prb/math/test/Utils.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

abstract contract Utils is StdUtils, PRBMathUtils {
    /// @dev Helper function to bound a `uint40` number.
    function boundUint40(uint40 x, uint40 min, uint40 max) internal view returns (uint40 result) {
        result = uint40(bound(uint256(x), uint256(min), uint256(max)));
    }

    /// @dev Helper function to bound a `uint40` number.
    function boundUint128(uint128 x, uint128 min, uint128 max) internal view returns (uint128 result) {
        result = uint128(bound(uint256(x), uint256(min), uint256(max)));
    }
}
