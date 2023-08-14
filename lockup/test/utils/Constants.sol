// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    bytes32 internal constant FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint40 internal constant MAY_1_2023 = 1_682_899_200;
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
}
