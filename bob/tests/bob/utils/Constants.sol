// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";
import { BaseConstants } from "@sablier/evm-utils/src/tests/BaseConstants.sol";

abstract contract Constants is BaseConstants {
    // Amounts
    uint128 public constant CURRENT_PRICE = 3000e8;
    uint128 public constant DEPOSIT_AMOUNT = 10e18;
    uint128 public constant LIDO_MAX_STETH_WITHDRAWAL_AMOUNT = 1000 ether;
    uint128 public constant LIDO_MIN_STETH_WITHDRAWAL_AMOUNT = 100 wei;
    uint128 public constant TARGET_PRICE = 4000e8;
    uint128 public constant WETH_STAKED = DEPOSIT_AMOUNT;
    UD60x18 public constant WSTETH_WETH_EXCHANGE_RATE = UD60x18.wrap(0.9e18);
    uint128 public immutable WSTETH_RECEIVED_FOR_DEPOSIT_AMOUNT =
        UD60x18.wrap(DEPOSIT_AMOUNT).mul(WSTETH_WETH_EXCHANGE_RATE).intoUint128();

    // Fees and Tolerances
    UD60x18 public constant MAX_SLIPPAGE_TOLERANCE = UD60x18.wrap(0.05e18); // 5%
    UD60x18 public constant MAX_YIELD_FEE = UD60x18.wrap(0.2e18); // 20%
    UD60x18 public constant SLIPPAGE_TOLERANCE = UD60x18.wrap(0.005e18); // 0.5%
    UD60x18 public constant YIELD_FEE = UD60x18.wrap(0.1e18); // 10%

    // Timestamps
    uint40 public constant FEB_1_2026 = 1_769_904_000;
    uint40 public constant EXPIRY = FEB_1_2026 + 30 days;

    // Vault Share
    string public constant SHARE_TOKEN_NAME = "Sablier Bob WETH Vault #1";
    string public constant SHARE_TOKEN_SYMBOL = "WETH-400000000000-1772496000-1";
    uint256 public constant WETH_DECIMALS = 18;
}
