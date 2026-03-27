### List of Invariants Implemented in [Invariant.t.sol](./Invariant.t.sol)

#### Non-Adapter Solvency

1. (Inv 3) For non-adapter vaults, `token.balanceOf(bob) >= sum of shareToken.totalSupply()`.
2. (Inv 5) Shares are minted 1:1 with deposits on `enter`.
3. (Inv 8) For non-adapter vaults, `shareToken.totalSupply() == totalDeposited - totalSharesBurned`.
4. (Inv 60) Redeem is all-or-nothing: user's share balance is zero after `redeem`.
5. (Inv 61) For non-adapter vaults, tokens transferred on `redeem` equal the user's prior share balance.
6. (Inv 62) When shares are burned on `redeem`, the user's token balance increases.

#### Creation-Time Properties

07. (Inv 65) Adapter vault has `isStakedInAdapter == true` after creation.
08. (Inv 66) Non-adapter vault has `isStakedInAdapter == false` after creation.
09. (Inv 68) `BobVaultShare.VAULT_ID()` matches the vault it was deployed for.
10. (Inv 69) `BobVaultShare.SABLIER_BOB()` matches `address(bob)`.

#### Cross-Contract Atomicity

11. (Inv 1) Broad solvency: non-adapter token balance sufficient + adapter distribution capped.
12. (Inv 11) For non-adapter, non-native enters, bob's token balance increases by deposit amount.
13. (Inv 82) `enterWithNativeToken` wraps exactly `msg.value` into shares.

#### Adapter Economics

14. (Inv 6) Yield fees must never exceed yield earned.
15. (Inv 24) Total WETH distributed across all redemptions $`\le`$ `wethReceivedAfterUnstaking`.
16. (Inv 27) No user receives more than their proportional WETH share based on wstETH attribution.

#### Adapter Aggregate

17. (Inv 26) After all users redeem, each depositor's wstETH balance is zero.

#### Additional Live-State Invariants

18. (Inv 12) No ETH should remain stuck in the `SablierBob` contract.
19. (Inv 18) Per-vault share token `totalSupply` equals the sum of all holder balances.
20. (Inv 28) `_vaultTotalWstETH` equals the sum of all `_userWstETH` for adapter vaults while staked.
21. (Inv 29) When shares are burned in `redeem`, `_userWstETH` is cleared for adapter vaults.
22. (Inv 72) `processRedemption` conservation: `transferAmount + fee` equals the user's proportional WETH share.
