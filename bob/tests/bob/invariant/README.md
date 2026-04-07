### List of Invariants Implemented in [Invariant.t.sol](./Invariant.t.sol)

#### Bob

1. `nextVaultId` = number of vaults created + 1.

2. For a given token $`\tau`$,

   - Across all vaults without adapter, $`\sum`$ deposits = $`\sum`$ tokens redeemed + $`\sum`$ share supply.
   - Token balance of Bob = $`\sum`$ deposit amount across vaults without adapter + $`\sum`$ tokens received from adapter - $`\sum`$ withdrawn amount by users across all vaults.

3. For a given vault,

   - the value of `isStakedInAdapter` can never change from `false` to `true`.
   - total supply of share tokens = $`\sum_{\text{vault}}`$ deposits - $`\sum_{\text{vault}}`$ shares burned.

4. For a given vault with adapter,

   - `amountReceivedFromAdapter` $`\ge`$ $`\sum_{user}`$ transfer amount + fee amount during redemption for each user.

5. For an active vault,

   - lastSyncedPrice $`\lt`$ targetPrice and `block.timestamp` $`\lt`$ expiry

6. For an expired vault,

   - `block.timestamp` $`\ge`$ expiry

7. For a settled vault,

   - lastSyncedPrice $`\ge`$ targetPrice and `block.timestamp` $`\lt`$ expiry

8. State transitions:

   - EXPIRED $`\not\to`$ { ACTIVE, SETTLED }
   - SETTLED $`\not\to`$ { ACTIVE }

#### Lido Adapter

1. `wstETH` balance of adapter = $`\sum_{\text{staked vaults}}`$ `wstETH` balance.

2. For a given vault with adapter,

   - If `isStakedInAdapter` = true, `wstETH` balance of vault = $`\sum_{\text{user}}`$ `wstETH` balance of each user.
   - If `isStakedInAdapter` = false, `wstETH` balance of vault $`\ge`$ $`\sum_{\text{user}}`$ `wstETH` balance of each user.

3. If share balance of a user = 0, $`\implies`$ `getYieldBearingTokenBalanceFor` = 0. If the user has share balance > 0, `getYieldBearingTokenBalanceFor` > 0.
