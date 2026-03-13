# Protocol Invariants

## SablierBob — Vault Mechanics

1. Users must not be able to steal other user deposits or receive an unfair share of yield — **broken by C-1** — *fixed after mitigation review*
2. A vault which has entered the SETTLED or EXPIRED states must not revert back to ACTIVE
3. For non-adapter vaults, total vault token balance held by `SablierBob` must be >= total outstanding share supply
4. A user must only be able to redeem when the vault is SETTLED or EXPIRED, never when ACTIVE
5. Share tokens must be minted 1:1 with deposited tokens on `enter`
6. Yield fees must never exceed the yield earned
7. `nextVaultId` must never decrease
8. For non-adapter vaults, the sum of tokens transferred in/out must equal the change in share token supply
9. A vault's `token`, `oracle`, `targetPrice`, `expiry`, and `shareToken` must never change after creation
10. `lastSyncedPrice` must only change via functions that call `_syncPriceFromOracle`
11. When `enter()` mints shares, a corresponding token transfer into `SablierBob` must occur in the same transaction
12. No ETH should remain stuck in the `SablierBob` contract after any function call — **broken by L-9** — *fixed after mitigation review*
13. Vaults can never be created with an expiry timestamp older than or equal to the current timestamp
14. Vaults can never be created with a target price lower than or equal to the current oracle price
15. `enter` and `syncPriceFromOracle` must revert when the vault is settled or expired
16. For non-adapter vaults, users must not be able to pay a redemption fee less than the `minFeeWei` configured by the comptroller
17. `lastSyncedPrice` and `lastSyncedAt` must only change when the oracle reports a positive price

## SablierBob — Share Token

18. Per-vault share token `totalSupply` must equal the sum of all holder balances
19. Only `SablierBob` can mint and burn share tokens

## SablierBob — Grace Period

20. Once the grace period has elapsed, users must not be able to exit a vault until the expiry period has been served — **broken by M-2** — *n/a after mitigation review*
21. Only the original depositor should be able to exit within the grace period — **broken by M-2** — *n/a after mitigation review*
22. `_firstDepositTimes[vaultId][user]` can only be modified by `enter` (setting it when zero) and `exitWithinGracePeriod` (resetting it to zero) — *n/a after mitigation review*
23. When `exitWithinGracePeriod()` burns shares, a corresponding token transfer to `msg.sender` must occur in the same transaction — *n/a after mitigation review*

## SablierBob — Adapter

24. For adapter vaults, total WETH distributed across all redemptions must not exceed `_wethReceivedAfterUnstaking` for that vault
25. `unstakeTokensViaAdapter` must only be callable once per vault
26. After all users of an adapter vault redeem, `_vaultTotalWstETH` for that vault should be zero — **broken by C-1** — *fixed after mitigation review*
27. A late depositor must not earn a disproportionate share of yield accumulated before their deposit
28. `_vaultTotalWstETH[vaultId]` must equal the sum of all `_userWstETH[vaultId][user]` — **broken by C-1** — *fixed after mitigation review*
29. When shares are burned in `redeem`, `_userWstETH` must be correspondingly cleared for adapter vaults — **broken by C-1** — *fixed after mitigation review*
30. `vault.isStakedInAdapter` can only transition `true` to `false`, never `false` to `true`
31. `_vaultYieldFee[vaultId]` once set at vault creation must never change
32. When `BobVaultShare` tokens are transferred (amount > 0), `updateStakedTokenBalance` must transfer a proportional amount of wstETH (> 0) to the recipient — **broken by M-3** — *fixed after mitigation review*
53. `feeOnYield` must never exceed `MAX_FEE`
54. `slippageTolerance` must never exceed `MAX_SLIPPAGE_TOLERANCE`
57. For a given vault, the Curve swap and Lido native withdrawal exit paths must be mutually exclusive — once one path is used, the other must be permanently blocked

## SablierEscrow

33. An escrow order which has entered the FILLED, CANCELLED or EXPIRED states must not revert back to OPEN
34. An escrow order can only be filled once
35. An escrow order can only be cancelled when OPEN
36. On cancellation, the full `sellAmount` must be returned to the seller
37. Trade fees must not exceed `MAX_TRADE_FEE`
38. Only the designated buyer can fill a private order; anyone can fill a public order
39. `nextOrderId` must never decrease
40. An order's `seller`, `buyer`, `sellToken`, `buyToken`, `sellAmount`, `minBuyAmount`, and `expiryTime` must never change after creation
41. `wasFilled` and `wasCanceled` once set to `true` must never revert to `false`
42. On `fillOrder`, `sellAmount` must be fully conserved: `amountToTransferToBuyer + feeDeductedFromBuyerAmount = sellAmount`
43. On `fillOrder`, `buyAmount` must be fully conserved: `amountToTransferToSeller + feeDeductedFromSellerAmount = buyAmount`
44. Only the seller who created the order can cancel it
45. The final `buyToken` amount received by the seller must be >= `minBuyAmount` — **broken by L-8**
50. `wasFilled` and `wasCanceled` must never both be `true` for the same order

## Cross-Cutting

46. Native tokens as defined by `nativeToken` must never be accepted as vault or order tokens
47. `nativeToken` once set to a non-zero value must never change
48. Only the comptroller can call admin functions (`setDefaultAdapter`, `setNativeToken`, `setTradeFee`, etc.)
49. Only `SablierBob` can call adapter operational functions (`stake`, `registerVault`, `unstakeFullAmount`, `updateStakedTokenBalance`)
55. `requestLidoWithdrawal` must only be callable by the comptroller
56. `processRedemption` must only be callable by `SablierBob`
