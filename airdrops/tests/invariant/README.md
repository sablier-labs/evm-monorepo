### List of Invariants

#### For all campaigns:

1. For non-VCA campaigns: token.balanceOf(campaign) = total deposit - $\\sum$ claimed - $\\sum$ clawbacked
2. For VCA campaigns: token.balanceOf(campaign) >= total deposit - $\\sum$ claimed - $\\sum$ clawbacked - $\\sum$
   redistribution rewards (due to rounding in the vesting calculation)
3. `hasClaimed` should never change its value from `true` to `false`
4. `minFeeUSD` should never increase

#### For VCA campaign:

1. total forgone amount = $\\sum$ claim amount requested - $\\sum$ claimed amount
2. total forgone amount should never decrease
3. If vesting has ended, total forgone amount should never change.
4. If redistribution is enabled and aggregate amount is correctly set,
   - Redistribution rewards for a fixed amount should never decrease.
   - If vesting has ended, redistribution rewards for a fixed amount should never change.
   - Rewards distributed should never exceed total forgone amount.
