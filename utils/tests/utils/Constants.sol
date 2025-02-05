// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

abstract contract CommonConstants {
    uint256 internal constant FEE = 0.001e18;
    uint40 internal constant FEB_1_2025 = 1_732_073_600;
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
    uint64 internal constant MAX_UINT64 = type(uint64).max;
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1
}
