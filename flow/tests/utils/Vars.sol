// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

/// @dev A struct to hold the variables in case a test throws stack too deep error.
struct Vars {
    IERC20 token;
    // previous values.
    uint256 previousAggregateAmount;
    uint256 previousOngoingDebtScaled;
    uint40 previousSnapshotTime;
    uint128 previousStreamBalance;
    uint256 previousTokenBalance;
    uint256 previousTotalDebt;
    // actual values.
    uint256 actualAggregateAmount;
    UD21x18 actualRatePerSecond;
    uint256 actualSnapshotDebtScaled;
    uint40 actualSnapshotTime;
    uint128 actualStreamBalance;
    uint256 actualStreamId;
    uint256 actualTokenBalance;
    uint256 actualTotalDebt;
    uint128 actualWithdrawnAmount;
    // expected values.
    uint256 expectedAggregateAmount;
    UD21x18 expectedRatePerSecond;
    uint256 expectedSnapshotDebtScaled;
    uint40 expectedSnapshotTime;
    uint128 expectedStreamBalance;
    uint256 expectedStreamId;
    uint256 expectedTokenBalance;
    uint256 expectedTotalDebt;
    uint128 expectedWithdrawAmount;
}
