# Formal Verification Report: Sablier Bob & Escrow

- Date: March 13th, 2026
- Audit Repo: https://github.com/Cyfrin/audit-2026-02-sablier-bob-2
- Client Repo: https://github.com/sablier-labs/lockup/tree/staging
- Audit Commit: 9fbc34f8ac384b0effcb6545cf387e42ec96f910
- Mitigation Commit: 7fae8429bdb2b88d4b0e63dcf25eb8a1477e5a8a
- Author: Specialist AI FV-Certora v1.0.6 created by [Dacian](https://x.com/DevDacian)
- Human Auditor: [Dacian](https://x.com/DevDacian) ([Cyfrin](https://x.com/cyfrin) private audit)
- Certora Prover version: 8.8.1

---

## Table of Contents

- [About Sablier Bob \& Escrow](#about-sablier-bob--escrow)
- [Formal Verification Methodology](#formal-verification-methodology)
- [Project Structure](#project-structure)
- [Verification Properties](#verification-properties)
  - [BobVaultShare (4 properties)](#bobvaultshare-4-properties)
  - [SablierBob (19 active + 4 n/a properties)](#sablierbob-19-active--4-na-properties)
  - [SablierEscrow (18 properties)](#sablierescrow-18-properties)
  - [SablierLidoAdapter (18 active + 1 n/a properties)](#sablierlidoadapter-18-active--1-na-properties)
- [Assumptions — Safe](#assumptions--safe)
- [Assumptions — Proved](#assumptions--proved)
- [Verification Results](#verification-results)
- [Setup and Execution](#setup-and-execution)
  - [Common Setup (Steps 1–4)](#common-setup-steps-14)
  - [Remote Execution](#remote-execution)
  - [Local Execution](#local-execution)
  - [Running Verification](#running-verification)
- [Resources](#resources)

---

## About Sablier Bob & Escrow

**Sablier Bob** is a price-gated vault protocol for conditional token releases with optional yield generation. Users deposit ERC-20 tokens into vaults that release based on price conditions — either when an oracle-synced price reaches a target (SETTLED) or when an expiry timestamp passes (EXPIRED). Each vault mints a `BobVaultShare` ERC-20 token on deposit (1:1 ratio). An optional Lido adapter enables yield generation by staking deposited WETH as wstETH, with support for both Curve swap and native Lido withdrawal paths.

**Sablier Escrow** is an over-the-counter (OTC) token swap protocol. Sellers create orders by depositing a sell token, specifying a buy token and minimum buy amount. Orders can be public (anyone fills) or private (designated buyer only). A configurable trade fee (max 2%) is deducted from both sides on fill. Orders expire after an optional expiry timestamp.

Contracts in scope:

| Contract | Description |
|----------|-------------|
| `SablierBob` | Singleton vault manager — create, enter, exit, sync, redeem |
| `BobVaultShare` | ERC-20 share token minted per vault on deposit |
| `SablierEscrow` | OTC escrow — create, fill, cancel orders |
| `SablierLidoAdapter` | Lido yield adapter — stake/unstake WETH as wstETH |

## Formal Verification Methodology

Certora Formal Verification (FV) provides mathematical proofs of smart contract correctness by verifying code against a formal specification. Unlike testing and fuzzing which examine specific execution paths, Certora FV examines all possible states and execution paths.

The process involves crafting properties in CVL (Certora Verification Language) and submitting them alongside compiled Solidity smart contracts to a remote prover. The prover transforms the contract bytecode and rules into a mathematical model and determines the validity of rules.

### Types of Properties

**Invariants** — System-wide properties that MUST always hold true. These are parametric — automatically verified against every external function in the contract. Once proven, invariants serve as trusted assumptions via `requireInvariant`.

**Parametric Rules** — Rules verified against every non-view external function using `method f` with `calldataarg args`. Used for properties like "only mint can increase totalSupply" or "counter values never decrease."

**Access Control Rules** — Rules verifying that state-changing functions revert when the caller lacks the required role. Uses the `@withrevert` pattern: call the function, then `assert !lastReverted => hasRole(...)`.

**Revert Condition Rules** — Rules verifying that functions revert under specific invalid conditions (zero inputs, paused state, missing allowlist, etc.). Uses `@withrevert` followed by `assert lastReverted`.

**Integrity Rules** — Rules verifying that successful function calls produce the correct state changes (e.g., transfer moves exact amounts, deposit records match inputs, preview functions match actual operations, round-trip conversions never inflate value).

**Sanity (Satisfy) Rules** — Lightweight reachability checks ensuring functions are not vacuously verified. Uses `satisfy true` to confirm at least one non-reverting execution path exists.

Key modeling decisions:

- **Oracle ghost variable**: Chainlink `latestRoundData()` is summarized via a ghost variable (`ghostOracleAnswer`) rather than `NONDET`, allowing rules to constrain oracle behavior while remaining unconstrained by default
- **MinFeeWei ghost variable**: `calculateMinFeeWei()` is summarized via a ghost variable (`ghostMinFeeWei`) rather than `NONDET`, allowing the Inv 16 rule to verify that `msg.value >= minFeeWei` on non-adapter redeems
- **External call summaries**: ERC-20 token functions (`transfer`, `transferFrom`, `balanceOf`, etc.) and adapter interactions are summarized as `NONDET` (conservative havoc)
- **Oracle decimals ghost variable**: `decimals()` is summarized via a ghost variable (`ghostOracleDecimals`) rather than `NONDET`. The updated `SafeOracle.safeOraclePrice` now normalizes prices to 8 decimals — without constraining decimals, NONDET could pick values causing normalization to multiply or divide the raw price, producing false counterexamples in oracle-dependent rules
- **MockComptroller link**: The comptroller state variable is linked to a minimal `MockComptroller` contract with `receive() payable {}`, enabling the prover to resolve low-level `address(comptroller).call{value}("")` to a concrete contract and correctly model ETH balance transfers via `nativeBalances`
- **Preserved blocks**: OpenZeppelin ERC-20 v5 `unchecked` arithmetic requires explicit invariant maintenance in `BobVaultShare` preserved blocks

## Project Structure

```
bob/certora/
├── README.md                      # This formal verification report (markdown)
├── README.pdf                     # This formal verification report (PDF)
├── invariants.md                  # Protocol invariants — source of truth for all verified properties
├── conf/
│   ├── BobVaultShare.conf          # Share token verification config
│   ├── SablierBob.conf             # Vault mechanics config
│   ├── SablierEscrow.conf          # OTC escrow config
│   └── SablierLidoAdapter.conf     # Lido adapter config
├── helper/
│   └── MockComptroller.sol         # Minimal mock with receive() for ETH transfer modeling
└── specs/
    ├── BobVaultShare.spec          # Inv 18–19: ERC-20 accounting and auth
    ├── SablierBob.spec             # Inv 2, 4, 7, 9, 10, 12–17, 25, 30, 46, 47, 48: Vault state machine (Inv 20, 22, 23 n/a)
    ├── SablierEscrow.spec          # Inv 33–46, 47, 48, 50: Order state machine and conservation
    └── SablierLidoAdapter.spec     # Inv 28, 31, 48, 49, 53–57 + C-1, L-7, M-3: Adapter yield, Lido withdrawal, access control
```

A `MockComptroller` helper contract provides a `receive() payable` function, enabling the Certora prover to correctly model ETH balance transfers via low-level `call{value}`. All internal state is accessible via public getters.

## Verification Properties

59 active properties across 4 contracts (5 additional properties marked n/a after mitigation review — grace period feature removed per finding M-2).

- Invariants: 1
- Parametric rules: 24
- Access control rules: 13
- Revert condition rules: 13
- Integrity rules: 5
- Conservation rules: 3

### BobVaultShare (4 properties)

ERC-20 share token accounting invariant and authorization.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| S-18 | `totalSupplyIsSumOfBalances` | Invariant | `totalSupply()` equals the sum of all individual balances (ghost sum with Sstore hook) | ✓ | ✓ |
| S-19 | `onlySablierBobCanChangeTotalSupply` | Parametric | If `totalSupply` changes, `msg.sender` must be the `SABLIER_BOB` address | ✓ | ✓ |
| S-18a | `transferPreservesTotalSupply` | Integrity | `transfer` does not change `totalSupply` | ✓ | ✓ |
| S-18b | `transferFromPreservesTotalSupply` | Integrity | `transferFrom` does not change `totalSupply` | ✓ | ✓ |

### SablierBob (19 active + 4 n/a properties)

Vault state machine, immutability, and authorization.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| B-2a | `settledVaultCannotBecomeActive` | Parametric | Once `lastSyncedPrice >= targetPrice` (SETTLED), `targetPrice` cannot change and `lastSyncedPrice` cannot decrease — vault stays SETTLED | ✓ | ✓ |
| B-2b | `expiredVaultCannotBecomeActive` | Parametric | Once `block.timestamp >= expiry` (EXPIRED), `expiry` is immutable — vault cannot un-expire | ✓ | ✓ |
| B-4 | `redeemRevertsWhenStillActive` | Revert Condition | `redeem` reverts if the vault is ACTIVE after internal price sync (oracle constrained below target with decimals=8, not expired) | ✓ | ✓ |
| B-7 | `nextVaultIdMonotonic` | Parametric | `nextVaultId` never decreases after any function call | ✓ | ✓ |
| B-9 | `vaultFieldsImmutable` | Parametric | Core vault fields (`token`, `oracle`, `targetPrice`, `expiry`, `shareToken`) never change after creation | ✓ | ✓ |
| B-10 | `lastSyncedPriceAuthorization` | Parametric | `lastSyncedPrice` can only be modified by `syncPriceFromOracle`, `enter`, `redeem`, `unstakeTokensViaAdapter`, or `createVault` | ✓ | ✓ |
| B-12 | `noEthStuckInContract` | Parametric | **Inv 12 / L-9 FIXED**: No ETH should remain stuck in `SablierBob` after any function call. Adapter vault ETH trapping fixed (L-9: `msg.value > 0` now reverts). Comptroller linked to MockComptroller (with `receive() payable`) so the prover correctly models ETH balance transfer via low-level `call{value}` | ✗ | ✓ |
| B-13 | `createVaultRevertsIfExpiryInPast` | Revert Condition | `createVault` reverts if `expiry <= block.timestamp` — vaults cannot be created with a past or current expiry | ✓ | ✓ |
| B-14 | `createVaultRevertsIfTargetPriceTooLow` | Revert Condition | `createVault` reverts if `targetPrice <= current oracle price` (with decimals=8) — vaults cannot be created with an already-reached target | ✓ | ✓ |
| B-15a | `enterRevertsWhenNotActive` | Revert Condition | `enter` reverts when the vault is SETTLED or EXPIRED | ✓ | ✓ |
| ~~B-15b~~ | ~~`exitWithinGracePeriodRevertsWhenNotActive`~~ | ~~Revert Condition~~ | ~~`exitWithinGracePeriod` reverts when the vault is SETTLED or EXPIRED~~ | ✓ | N/A |
| B-15c | `syncPriceRevertsWhenNotActive` | Revert Condition | `syncPriceFromOracle` reverts when the vault is SETTLED or EXPIRED | ✓ | ✓ |
| B-16 | `nonAdapterRedeemRequiresMinFee` | Revert Condition | For non-adapter vaults, `redeem` reverts when `msg.value < minFeeWei` — users cannot pay less than the comptroller-configured minimum fee | ✓ | ✓ |
| B-17 | `lastSyncedPriceChangesOnlyOnPositiveOracle` | Parametric | `lastSyncedPrice` and `lastSyncedAt` can only change when the oracle reports a positive price (`ghostOracleAnswer > 0`) | ✓ | ✓ |
| ~~B-20~~ | ~~`exitRevertsAfterGracePeriod`~~ | ~~Revert Condition~~ | ~~`exitWithinGracePeriod` reverts when `block.timestamp >= firstDepositTime + GRACE_PERIOD`~~ | ✓ | N/A |
| ~~B-22~~ | ~~`firstDepositTimeImmutableOnceSet`~~ | ~~Parametric~~ | ~~`firstDepositTime` can only be modified by `enter` (setting when zero) and `exitWithinGracePeriod` (resetting to zero)~~ | ✓ | N/A |
| ~~B-23~~ | ~~`exitWithinGracePeriodClearsDepositTime`~~ | ~~Integrity~~ | ~~`exitWithinGracePeriod` clears the user's `firstDepositTime` to zero~~ | ✓ | N/A |
| B-47 | `nativeTokenSetOnce` | Parametric | Once `nativeToken` is set to non-zero, no function can change it | ✓ | ✓ |
| B-48a | `setNativeTokenOnlyComptroller` | Access Control | `setNativeToken` reverts if `msg.sender` is not the comptroller | ✓ | ✓ |
| B-48b | `setDefaultAdapterOnlyComptroller` | Access Control | `setDefaultAdapter` reverts if `msg.sender` is not the comptroller | ✓ | ✓ |
| B-25 | `unstakeTokensViaAdapterCallableOnce` | Revert Condition | **NEW (Inv 25)**: `unstakeTokensViaAdapter` reverts if the vault has already been unstaked (`isStakedInAdapter == false`) | | ✓ |
| B-30 | `isStakedInAdapterOnlyTrueToFalse` | Parametric | **NEW (Inv 30)**: `isStakedInAdapter` can only transition `true → false`, never `false → true` — excludes `createVault` (sets initial value) | | ✓ |
| B-46 | `createVaultRejectsNativeToken` | Revert Condition | **NEW (Inv 46)**: `createVault` reverts if the vault token equals `nativeToken` | | ✓ |

### SablierEscrow (18 properties)

Order state machine, monotonic flags, conservation on fill, and authorization.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| E-33 | `orderStateIrreversibility` | Parametric | Once `wasFilled` or `wasCanceled` is true (terminal state), it cannot revert to false | ✓ | ✓ |
| E-34 | `wasFilledMonotonic` | Parametric | `wasFilled` once true stays true — no second fill possible | ✓ | ✓ |
| E-35 | `cancelRevertsIfFilled` | Revert Condition | `cancelOrder` reverts if the order has already been filled | ✓ | ✓ |
| E-37 | `tradeFeeNotTooHigh` | Parametric | `tradeFee` never exceeds `MAX_TRADE_FEE` after any state change | ✓ | ✓ |
| E-38 | `privateOrderBuyerEnforcement` | Revert Condition | `fillOrder` reverts if the order has a designated buyer and `msg.sender` is not that buyer | ✓ | ✓ |
| E-39 | `nextOrderIdMonotonic` | Parametric | `nextOrderId` never decreases after any function call | ✓ | ✓ |
| E-40 | `orderFieldsImmutable` | Parametric | Core order fields (`seller`, `buyer`, `sellToken`, `buyToken`, `sellAmount`, `minBuyAmount`, `expiryTime`) never change after creation | ✓ | ✓ |
| E-41 | `wasCanceledMonotonic` | Parametric | `wasCanceled` once true stays true | ✓ | ✓ |
| E-42 | `sellAmountConservationOnFill` | Conservation | On `fillOrder`, `amountToTransferToBuyer + feeDeductedFromBuyerAmount == sellAmount` | ✓ | ✓ |
| E-43 | `buyAmountConservationOnFill` | Conservation | On `fillOrder`, `amountToTransferToSeller + feeDeductedFromSellerAmount == buyAmount` | ✓ | ✓ |
| E-44 | `onlySellerCanCancel` | Access Control | `cancelOrder` reverts if `msg.sender` is not the seller who created the order | ✓ | ✓ |
| E-45 | `sellerReceivesAtLeastMinBuyAmount` | Integrity | **Inv 45 / L-8**: Expected FAIL — the trade fee is deducted from `buyAmount`, so `amountToTransferToSeller = buyAmount - fee` can be less than `minBuyAmount` when the buyer pays exactly `minBuyAmount` and the fee is non-zero | ✗ | ✗ |
| E-50 | `filledAndCanceledMutuallyExclusive` | Parametric | `wasFilled` and `wasCanceled` can never both be true for the same order — inductive proof assuming mutual exclusion holds before any function call | ✓ | ✓ |
| E-47 | `nativeTokenSetOnce` | Parametric | Once `nativeToken` is set to non-zero, no function can change it | ✓ | ✓ |
| E-48a | `setTradeFeeOnlyComptroller` | Access Control | `setTradeFee` reverts if `msg.sender` is not the comptroller | ✓ | ✓ |
| E-48b | `setNativeTokenOnlyComptroller` | Access Control | `setNativeToken` reverts if `msg.sender` is not the comptroller | ✓ | ✓ |
| E-46a | `createOrderRejectsNativeSellToken` | Revert Condition | **NEW (Inv 46)**: `createOrder` reverts if `sellToken` equals `nativeToken` | | ✓ |
| E-46b | `createOrderRejectsNativeBuyToken` | Revert Condition | **NEW (Inv 46)**: `createOrder` reverts if `buyToken` equals `nativeToken` | | ✓ |

### SablierLidoAdapter (18 active + 1 n/a properties)

Adapter yield fee immutability, parameter bounds, WETH distribution conservation, Lido withdrawal, and access control.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| L-C1 | `userWstETHClearedAfterRedemption` | Integrity | **Inv 29 / C-1 FIXED**: `processRedemption` (renamed from `calculateAmountToTransferWithYield`) now includes `delete _userWstETH[vaultId][user]`, clearing the user's wstETH balance after computing WETH payout — prevents repeated redemption via share recycling | ✗ | ✓ |
| L-L7 | `wethDistributionConservation` | Conservation | **Inv 24 / L-7**: `processRedemption` uses floor division — sum of individual WETH shares < total WETH received, leaving dust stuck in contract with no recovery mechanism | ✗ | ✗ |
| L-31 | `vaultYieldFeeImmutable` | Parametric | Once a vault's yield fee is set via `registerVault`, no function can modify it | ✓ | ✓ |
| L-48a | `setYieldFeeOnlyComptroller` | Access Control | `setYieldFee` reverts if `msg.sender` is not the comptroller | ✓ | ✓ |
| L-48b | `setSlippageToleranceOnlyComptroller` | Access Control | `setSlippageTolerance` reverts if `msg.sender` is not the comptroller | ✓ | ✓ |
| L-49a | `stakeOnlySablierBob` | Access Control | `stake` reverts if `msg.sender` is not `SABLIER_BOB` | ✓ | ✓ |
| L-49b | `registerVaultOnlySablierBob` | Access Control | `registerVault` reverts if `msg.sender` is not `SABLIER_BOB` | ✓ | ✓ |
| ~~L-49c~~ | ~~`unstakeForUserOnlySablierBob`~~ | ~~Access Control~~ | ~~`unstakeForUserWithinGracePeriod` reverts if `msg.sender` is not `SABLIER_BOB`~~ | ✓ | N/A |
| L-49d | `unstakeFullAmountOnlySablierBob` | Access Control | `unstakeFullAmount` reverts if `msg.sender` is not `SABLIER_BOB` | ✓ | ✓ |
| L-49e | `updateStakedTokenBalanceOnlySablierBob` | Access Control | `updateStakedTokenBalance` reverts if `msg.sender` is not `SABLIER_BOB` | ✓ | ✓ |
| L-53 | `feeOnYieldNotTooHigh` | Parametric | `feeOnYield` never exceeds `MAX_FEE` after any state change | ✓ | ✓ |
| L-54 | `slippageToleranceNotTooHigh` | Parametric | `slippageTolerance` never exceeds `MAX_SLIPPAGE_TOLERANCE` after any state change | ✓ | ✓ |
| L-M3 | `nonZeroShareTransferMovesWstETH` | Integrity | **Inv 32 / M-3 FIXED**: `updateStakedTokenBalance` now reverts when the computed wstETH transfer amount is zero — prevents unbacked share transfers from floor division truncation | ✗ | ✓ |
| L-55 | `requestLidoWithdrawalOnlyComptroller` | Access Control | **NEW (Inv 55)**: `requestLidoWithdrawal` reverts if `msg.sender` is not the comptroller | | ✓ |
| L-56 | `processRedemptionOnlySablierBob` | Access Control | **NEW (Inv 56)**: `processRedemption` reverts if `msg.sender` is not `SABLIER_BOB` | | ✓ |
| L-57a | `lidoWithdrawalRequestIdsMonotonic` | Parametric | **NEW (Inv 57)**: Once Lido withdrawal request IDs are set for a vault, no function can clear them — Curve path permanently blocked | | ✓ |
| L-57b | `requestLidoWithdrawalIdempotent` | Revert Condition | **NEW (Inv 57)**: `requestLidoWithdrawal` reverts if Lido withdrawal already requested for the vault | | ✓ |
| L-57c | `curvePathBlocksLidoPath` | Parametric | **NEW (Inv 57)**: If a vault was unstaked via Curve, no function can set Lido withdrawal request IDs for that vault | | ✓ |
| L-28 | `vaultTotalWstETHEqualsSumUserWstETH` | Parametric | **NEW (Inv 28)**: `_vaultTotalWstETH[vaultId]` equals the ghost sum of all `_userWstETH[vaultId][user]` after any function except `processRedemption` (which intentionally desyncs — total is snapshot denominator for proportional WETH distribution) | | ✓ |

## Assumptions — Safe

The following `require` statements are used in specs to constrain the prover to realistic states. Each is annotated with `"safe: ..."` in the spec source.

| Assumption | Used In | Justification |
|------------|---------|---------------|
| `vaultId < nextVaultId()` | B-2a–B-23 | Only valid vault IDs that have been created |
| `orderId < nextOrderId()` | E-33–E-45 | Only valid order IDs that have been created |
| `targetPrice > 0` | B-2a, B-4, B-14, B-15 | Valid vaults always have non-zero target price (set in `createVault`) |
| `expiry > 0` | B-2b, B-15 | Valid vaults always have non-zero expiry (enforced by `createVault`) |
| `lastPrice >= targetPrice` | B-2a | Precondition for SETTLED state |
| `lastPrice < targetPrice` | B-4 | Precondition for ACTIVE state (price below target) |
| `e.block.timestamp < expiry` | B-4 | Precondition for non-expired vault |
| `e.block.timestamp >= expiry` | B-2b | Precondition for EXPIRED state |
| `token != 0` | B-13 | Non-zero token to reach the expiry check (skips earlier token-zero revert) |
| `e.block.timestamp <= max_uint40` | B-13 | Solidity casts `block.timestamp` to `uint40` at L113; without this, the prover exploits wrap-around (year 36,812 unreachable) |
| `expiry <= e.block.timestamp` | B-13 | Testing that creating vault with past/current expiry reverts |
| `ghostOracleAnswer > 0` | B-14 | Oracle reports a positive answer |
| `ghostOracleAnswer >= targetPrice` | B-14 | Oracle price at or above target price |
| `ghostOracleAnswer < targetPrice` | B-4 | Models oracle not reporting settlement price — ensures vault stays ACTIVE after internal sync |
| `lastPrice >= targetPrice \|\| timestamp >= expiry` | B-15a/b/c | Vault is in non-ACTIVE state (SETTLED or EXPIRED) |
| `getAdapter(vaultId) == 0` | B-16 | Vault has no adapter (non-adapter vault) |
| `ghostMinFeeWei > 0` | B-16 | Min fee must be positive for the check to be meaningful |
| `msg.value < ghostMinFeeWei` | B-16 | Fee payment is below minimum (testing revert condition) |
| `ghostOracleDecimals == 8` | B-4, B-14 | Oracle decimals is 8 so normalization in `SafeOracle` is identity; consistent with how vaults are created with 8-decimal Chainlink feeds |
| `nativeBefore != 0` | B-47, E-47 | Native token must already be set to test set-once pattern |
| `e.msg.sender != seller` | E-44 | Caller is not the order seller (testing access control) |
| `userWstETH > 0` | L-C1 | User must have staked wstETH to test redemption clearing |
| `totalWeth > 0` | L-C1, L-L7 | Vault must have been unstaked (WETH received) |
| `totalWstETH > 0` | L-C1, L-L7 | Vault must have total wstETH balance |
| `amount > 0` | L-C1 | User must have a non-zero WETH claim |
| `idBefore < max_uint256` | B-7, E-39 | 2^256 − 1 vaults/orders is physically unreachable; excludes unchecked counter wrap |
| `feeBefore <= maxFee` | E-37, L-53 | Initial state satisfies the fee bound (inductive hypothesis) |
| `toleranceBefore <= maxTolerance` | L-54 | Initial state satisfies the tolerance bound (inductive hypothesis) |
| `!(filledBefore && canceledBefore)` | E-50 | Inductive hypothesis — mutual exclusion holds before call |
| `designatedBuyer != 0` | E-38 | Order must be private (has designated buyer) |
| `feeBefore != 0` | L-31 | Vault must have been registered (yield fee was snapshotted) |
| `from != to` | L-M3 | Distinct sender and receiver addresses |
| `nativeBalances[currentContract] == 0` | B-12 | SablierBob has no `receive()` or `fallback()`; constructor is not payable; ETH balance starts at 0 (inductive step) |
| MockComptroller link | B-12 | Comptroller linked to a concrete `MockComptroller` (with `receive() payable {}`), enabling the prover to correctly model ETH transfer via low-level `call{value}` |
| `setComptroller` filtered | All parametric | `setComptroller` writes the `comptroller` state variable which conflicts with the MockComptroller link (vacuous sanity failure); non-payable admin function that never modifies vault fields, nextVaultId, nativeToken, lastSyncedPrice/At, or ETH balances |
| `shareAmountTransferred > 0` | L-M3 | Non-zero share transfer (core precondition for the property) |
| `userShareBalanceBeforeTransfer >= shareAmountTransferred` | L-M3 | Valid transfer — sender has enough shares |
| `fromWstETH > 0` | L-M3 | Sender must have wstETH backing to test proportional transfer |
| `ghostLidoRequestCount[vaultId] > 0` | L-57a, L-57b | Lido withdrawal has been requested for this vault (precondition to test monotonicity/idempotency) |
| `ghostWethReceived[vaultId] > 0` | L-57c | Vault has been unstaked — WETH received from Curve swap |
| `ghostLidoRequestCount[vaultId] == 0` | L-57c | Vault was unstaked via Curve path (no Lido request IDs) |
| `!ghostIsStakedInAdapter[vaultId]` | L-57c | SablierBob sets `isStakedInAdapter=false` when `unstakeFullAmount` succeeds |
| Balance sum ≤ totalSupply | S-18 preserved | Any two balances sum to at most `totalSupply` when invariant holds |
| `totalSupply + amount ≤ max_uint256` | S-18 preserved | OZ ERC-20 uses checked addition for `_totalSupply` on mint |
| `!isStakedInAdapter(vaultId)` | B-30 | Precondition: vault is not staked — testing that `false` cannot transition to `true` |
| `!isStakedInAdapter(vaultId)` | B-25 | Vault has already been unstaked — testing `unstakeTokensViaAdapter` reverts |
| `e.msg.value == 0` | B-25 | `unstakeTokensViaAdapter` is not payable |
| `native != 0` | B-46, E-46a, E-46b | `nativeToken` must be set for the native token check to be meaningful |
| `token == native` | B-46 | Attempting to create vault with native token — testing revert |
| `sellToken == native` | E-46a | Attempting to use native token as sell token — testing revert |
| `buyToken == native` | E-46b | Attempting to use native token as buy token — testing revert |
| `sellToken != native && sellToken != 0` | E-46b | Bypass earlier reverts to reach the buy token check |
| `getTotalYieldBearingTokenBalance == ghostSum` | L-28 | Inductive hypothesis — total equals sum before function call |
| `transferFeesToComptroller` filtered | L-28, L-57a, L-57c | Low-level `call{value}("")` triggers HAVOC_ALL on adapter storage — false positive since it only sends ETH |

## Assumptions — Proved

The following invariant is used as a precondition via `requireInvariant` in preserved blocks:

| Invariant | Used In | Purpose |
|-----------|---------|---------|
| `totalSupplyIsSumOfBalances` (S-18) | S-18 preserved blocks | Required for induction step: confirms balance bounds hold so that OZ unchecked arithmetic in `_update()` cannot wrap |

---

## Verification Results

Final prover run URLs (Certora Prover v8.8.1). All 59 active properties verified; the 2 expected violations correspond to documented bugs (L-7 and L-8).

| Spec | Result | Prover URL |
|------|--------|-----------|
| BobVaultShare | All 4 rules pass | [Prover Link](https://prover.certora.com/output/4319676/cc4d65c1c52c4aab86ba85a9711618a7?anonymousKey=7b8e31c6f9e6a5930060f36111977bcfb57f8389) |
| SablierBob | All 19 rules pass | [Prover Link](https://prover.certora.com/output/4319676/78f547debf0e4502a2882f8ddeb4b606?anonymousKey=59050875f6f0eb2182aa601f96ade9e1d88e9099) |
| SablierEscrow | 17 pass, 1 expected fail (E-45/L-8) | [Prover Link](https://prover.certora.com/output/4319676/a5a77b5bb1464681afea6a01dfb50aa1?anonymousKey=9e25a869c800a438563eda42b95143353523b4d2) |
| SablierLidoAdapter | 17 pass, 1 expected fail (L-L7) | [Prover Link](https://prover.certora.com/output/4319676/db3b58a8e97a4dacb949647dde0f3f51?anonymousKey=d2eb5886d249cea41eb6e64934c4eea4a591597b) |

## Setup and Execution

The Certora Prover can be run either remotely (using Certora's cloud infrastructure) or locally (building from source); both modes share the same initial setup steps.

### Common Setup (Steps 1–4)

The instructions below are for Ubuntu 24.04. For step-by-step installation details refer to this setup [tutorial](https://alexzoid.com/first-steps-with-certora-fv-catching-a-real-bug#heading-setup).

1. Install Java (tested with JDK 21)

```bash
sudo apt update
sudo apt install default-jre
java -version
```

2. Install [pipx](https://pipx.pypa.io/) — installs Python CLI tools in isolated environments, avoiding dependency conflicts

```bash
sudo apt install pipx
pipx ensurepath
```

3. Install Certora CLI. To match a specific prover version, pin it explicitly (e.g. `certora-cli==8.8.1`)

```bash
pipx install certora-cli
```

4. Install solc-select and the Solidity compiler version required by the project

```bash
pipx install solc-select
solc-select install 0.8.29
solc-select use 0.8.29
```

### Remote Execution

5. Set up Certora key. You can get a free key through the Certora [Discord](https://discord.gg/certora) or on their website. Once you have it, export it:

```bash
echo "export CERTORAKEY=<your_certora_api_key>" >> ~/.bashrc
source ~/.bashrc
```

> **Note:** If a local prover is installed (see below), it takes priority. To force remote execution, add the `--server production` flag:
> ```bash
> certoraRun certora/conf/BobVaultShare.conf --server production
> ```

### Local Execution

Follow the full build instructions in the [CertoraProver repository (v8.8.1)](https://github.com/Certora/CertoraProver/tree/8.8.1). Once the local prover is installed it takes priority over the remote cloud by default. Tested on Ubuntu 24.04.

1. Install prerequisites

```bash
# JDK 19+
sudo apt install openjdk-21-jdk

# SMT solvers (z3 and cvc5 are required, others are optional)
# Download binaries and place them in PATH:
#   z3:   https://github.com/Z3Prover/z3/releases
#   cvc5: https://github.com/cvc5/cvc5/releases

# LLVM tools
sudo apt install llvm

# Rust 1.81.0+
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install rustfilt

# Graphviz (optional, for visual reports)
sudo apt install graphviz
```

2. Set up build output directory

```bash
export CERTORA="$HOME/CertoraProver/target/installed/"
mkdir -p "$CERTORA"
export PATH="$CERTORA:$PATH"
```

3. Clone and build

```bash
git clone --recurse-submodules https://github.com/Certora/CertoraProver.git
cd CertoraProver
git checkout tags/8.8.1
./gradlew assemble
```

4. Verify installation with test example

```bash
certoraRun.py -h
cd Public/TestEVM/Counter
certoraRun counter.conf
```

### Running Verification

All commands should be run from the `bob/` directory.

**Full spec verification** (one command per contract):

```bash
certoraRun certora/conf/BobVaultShare.conf
certoraRun certora/conf/SablierBob.conf
certoraRun certora/conf/SablierEscrow.conf
certoraRun certora/conf/SablierLidoAdapter.conf
```

**Single rule execution** (useful for debugging):

```bash
certoraRun certora/conf/SablierBob.conf --rule settledVaultCannotBecomeActive
certoraRun certora/conf/SablierEscrow.conf --rule sellAmountConservationOnFill
```

**Compilation-only check** (validates specs compile without submitting to prover):

```bash
certoraRun certora/conf/BobVaultShare.conf --compilation_steps_only
certoraRun certora/conf/SablierBob.conf --compilation_steps_only
certoraRun certora/conf/SablierEscrow.conf --compilation_steps_only
certoraRun certora/conf/SablierLidoAdapter.conf --compilation_steps_only
```

---

## Resources

To learn more about Certora formal verification:

- [Updraft Assembly & Formal Verification Course](https://updraft.cyfrin.io/courses/formal-verification) — Comprehensive video course covering assembly and formal verification from the ground up
- [Find Highs Using Certora Formal Verification](https://dacian.me/find-highs-before-external-auditors-using-certora-formal-verification) — Practical guide with a companion [repo](https://github.com/devdacian/solidity-fuzzing-comparison) containing simplified examples based on real code and bugs from private audits
- [RareSkills Certora Book](https://rareskills.io/tutorials/certora-book) — Structured tutorial covering CVL syntax, patterns, and common pitfalls
- [Alex FV Resources](https://github.com/alexzoid-eth/fv-resources) — Curated collection of formal verification resources, examples, and references
- [Certora Tutorials](https://docs.certora.com/en/latest/docs/user-guide/tutorials.html) — Official Certora documentation and guided tutorials
