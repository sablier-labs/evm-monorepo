# Formal Verification Report: Sablier Bob & Escrow

- Date: March 27th, 2026
- Audit Repo: https://github.com/Cyfrin/audit-2026-02-sablier-bob-2
- Client Repo: https://github.com/sablier-labs/evm-monorepo/tree/staging
- Audit Commit: 9fbc34f8ac384b0effcb6545cf387e42ec96f910
- Mitigation Commit: ffae95821335a4ddd7c1a54638aa5ffed36819b2
- Author: Bastion v1.2.4 created by [Dacian](https://x.com/DevDacian)
- Human Auditor: [Dacian](https://x.com/DevDacian) ([Cyfrin](https://x.com/cyfrin) private audit)
- Certora Prover version: 8.8.1

---

## Table of Contents

- [About Sablier Bob and Escrow](#about-sablier-bob-and-escrow)
- [Formal Verification Methodology](#formal-verification-methodology)
- [Project Structure](#project-structure)
- [Verification Properties](#verification-properties)
  - [BobVaultShare (6 properties)](#bobvaultshare-6-properties)
  - [SablierBob (32 active, 4 n/a properties)](#sablierbob-32-active-4-na-properties)
  - [SablierEscrow (29 properties)](#sablierescrow-29-properties)
  - [SablierLidoAdapter (21 active, 1 n/a properties)](#sablierlidoadapter-21-active-1-na-properties)
- [Assumptions - Safe](#assumptions---safe)
- [Assumptions - Proved](#assumptions---proved)
- [Verification Results](#verification-results)
- [Setup and Execution](#setup-and-execution)
  - [Common Setup (Steps 1-4)](#common-setup-steps-1-4)
  - [Remote Execution](#remote-execution)
  - [Local Execution](#local-execution)
  - [Running Verification](#running-verification)
- [Resources](#resources)

---

## About Sablier Bob and Escrow

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

**Access Control Rules** — Parametric state-change rules verifying that only authorized callers can modify critical state variables. For each protected variable, a parametric rule snapshots state before and after every function call, then asserts: if state changed, the caller must hold the required role. This is strictly stronger than function-specific `@withrevert` testing because it catches unauthorized modifications by unexpected functions.

**Revert Condition Rules** — Rules verifying that functions revert under specific invalid conditions (zero inputs, paused state, missing allowlist, etc.). Uses `@withrevert` followed by `assert lastReverted`.

**Integrity Rules** — Rules verifying that successful function calls produce the correct state changes (e.g., transfer moves exact amounts, deposit records match inputs, preview functions match actual operations, round-trip conversions never inflate value).

**Reachability Rules** — Targeted `satisfy` rules proving specific scenarios are reachable (e.g., deadlock detection, edge case paths). General vacuity checking is handled by `rule_sanity: "basic"` in the conf file rather than per-function `satisfy true` rules.

Key modeling decisions:

- **Oracle ghost variable**: Chainlink `latestRoundData()` is summarized via a ghost variable (`ghostOracleAnswer`) rather than `NONDET`, allowing rules to constrain oracle behavior while remaining unconstrained by default
- **MinFeeWei ghost variable**: `calculateMinFeeWei()` is summarized via a ghost variable (`ghostMinFeeWei`) rather than `NONDET`, allowing the Inv 16 rule to verify that `msg.value >= minFeeWei` on non-adapter redeems
- **CVL Ghost ERC20 Model**: Token interactions use a CVL ghost-based ERC20 model (Pattern A103) with SafeERC20 internal summaries. This enables concrete balance tracking for per-vault/per-order tokens without needing `link` directives. External wildcard summaries for `transfer`/`transferFrom` are intentionally omitted to prevent double ghost updates with SafeERC20 summaries (Gotcha 198)
- **Adapter interactions**: Adapter functions (`stake`, `unstakeFullAmount`, `processRedemption`, etc.) are summarized as `NONDET` (conservative havoc) — adapter state verified separately in `SablierLidoAdapter.spec`
- **commonFilters**: All parametric rules use a standard `commonFilters` definition including `f.contract == currentContract` to prevent the prover from calling linked contract functions directly
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
│   ├── MockComptroller.sol         # Minimal mock with receive() for ETH transfer modeling
│   ├── DummyERC20Impl.sol          # Minimal ERC-20 implementation for concrete balance tracking
│   ├── DummyERC20A.sol             # DummyERC20 instance A
│   └── DummyERC20B.sol             # DummyERC20 instance B
└── specs/
    ├── BobVaultShare.spec          # Inv 18–19, 70: ERC-20 accounting, auth, vault ID enforcement
    ├── SablierBob.spec             # Vault state machine, access control, immutability, token integrity
    ├── SablierEscrow.spec          # Order state machine, conservation, access control, input validation
    ├── SablierLidoAdapter.spec     # Adapter yield, conservation, access control, Lido withdrawal
    └── summarization/
        └── ERC20.spec              # CVL Ghost ERC20 Model with SafeERC20 internal summaries
```

Helper contracts: `MockComptroller` provides `receive() payable` for ETH transfer modeling. `DummyERC20Impl`/`A`/`B` provide concrete ERC-20 behavior for balance tracking. `ERC20.spec` implements a CVL ghost-based ERC20 model (Pattern A103) using SafeERC20 internal summaries to track per-token balances without `link` directives.

## Verification Properties

88 active properties across 4 contracts (5 additional properties marked n/a after mitigation review — grace period feature removed per finding M-2).

- Invariants: 1
- Parametric rules: 34
- Access control rules: 9
- Revert condition rules: 27
- Integrity rules: 8
- Conservation rules: 7
- Expected violations: 3 (L-7 dust, L-8 fee deduction — known findings)

### BobVaultShare (6 properties)

ERC-20 share token accounting invariant, authorization, and vault ID enforcement.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| S-18 | `totalSupplyIsSumOfBalances` | Invariant | `totalSupply()` equals the sum of all individual balances (ghost sum with Sstore hook) | ✓ | ✓ |
| S-19 | `onlySablierBobCanChangeTotalSupply` | Parametric | If `totalSupply` changes, `msg.sender` must be the `SABLIER_BOB` address | ✓ | ✓ |
| S-18a | `transferPreservesTotalSupply` | Integrity | `transfer` does not change `totalSupply` | ✓ | ✓ |
| S-18b | `transferFromPreservesTotalSupply` | Integrity | `transferFrom` does not change `totalSupply` | ✓ | ✓ |
| S-70a | `mintRevertsOnVaultIdMismatch` | Revert Condition | **Inv 70**: `BobVaultShare::mint` reverts if the provided `vaultId` does not match the token's immutable `VAULT_ID` | | ✓ |
| S-70b | `burnRevertsOnVaultIdMismatch` | Revert Condition | **Inv 70**: `BobVaultShare::burn` reverts if the provided `vaultId` does not match the token's immutable `VAULT_ID` | | ✓ |

### SablierBob (32 active, 4 n/a properties)

Vault state machine, immutability, parametric access control, cross-variable consistency, token integrity, and native token entry.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| B-2a | `settledVaultCannotBecomeActive` | Parametric | Once `lastSyncedPrice >= targetPrice` (SETTLED), `targetPrice` cannot change and `lastSyncedPrice` cannot decrease — vault stays SETTLED | ✓ | ✓ |
| B-2b | `expiredVaultCannotBecomeActive` | Parametric | Once `block.timestamp >= expiry` (EXPIRED), `expiry` is immutable — vault cannot un-expire | ✓ | ✓ |
| B-4 | `redeemRevertsWhenStillActive` | Revert Condition | `redeem` reverts if the vault is ACTIVE after internal price sync (oracle constrained below target with decimals=8, not expired) | ✓ | ✓ |
| B-7 | `nextVaultIdMonotonic` | Parametric | `nextVaultId` never decreases after any function call | ✓ | ✓ |
| B-9 | `vaultFieldsImmutable` | Parametric | **Inv 9, 67**: Core vault fields (`token`, `oracle`, `targetPrice`, `expiry`, `shareToken`, `adapter`) never change after creation. `adapter` added per Inv 67 | ✓ | ✓ |
| B-10 | `lastSyncedPriceAuthorization` | Parametric | `lastSyncedPrice` can only be modified by `syncPriceFromOracle`, `enter`, `enterWithNativeToken`, `redeem`, `unstakeTokensViaAdapter`, or `createVault` | ✓ | ✓ |
| B-12 | `noEthStuckInContract` | Parametric | **Inv 12 / L-9 FIXED**: No ETH should remain stuck in `SablierBob` after any function call. `enterWithNativeToken` filtered (NONDET on WETH deposit prevents ETH balance tracking; ETH is correctly forwarded on all code paths) | ✗ | ✓ |
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
| B-1 | `onlyComptrollerCanChangeNativeToken` | Access Control | **Inv 48**: Parametric state-change — if `nativeToken` changes, `msg.sender` must be comptroller | ✓ | ✓ |
| B-2 | `onlyComptrollerCanChangeDefaultAdapter` | Access Control | **Inv 48**: Parametric state-change — if `defaultAdapter` changes for any token, `msg.sender` must be comptroller | ✓ | ✓ |
| B-25 | `unstakeTokensViaAdapterCallableOnce` | Revert Condition | **Inv 25**: `unstakeTokensViaAdapter` reverts if the vault has already been unstaked (`isStakedInAdapter == false`) | | ✓ |
| B-30 | `isStakedInAdapterOnlyTrueToFalse` | Parametric | **Inv 30**: `isStakedInAdapter` can only transition `true → false`, never `false → true` — excludes `createVault` (sets initial value) | | ✓ |
| B-46 | `createVaultRejectsNativeToken` | Revert Condition | **Inv 46**: `createVault` reverts if the vault token equals `nativeToken` | | ✓ |
| B-58 | `createVaultRevertsTokenZero` | Revert Condition | **Inv 58**: `createVault` reverts if the `token` address is zero | | ✓ |
| B-59 | `createVaultRevertsTargetPriceZero` | Revert Condition | **Inv 59**: `createVault` reverts if `targetPrice` is zero | | ✓ |
| B-63 | `adapterVaultRedeemRevertsWithValue` | Revert Condition | **Inv 63**: `redeem` reverts with `msg.value > 0` for adapter vaults — prevents accidental ETH loss since adapter vault fees are deducted from yield | | ✓ |
| B-64 | `onShareTransferRevertsWrongCaller` | Revert Condition | **Inv 64**: `onShareTransfer` reverts if the caller is not the vault's designated share token contract | | ✓ |
| B-81 | `enterWithNativeTokenRevertsZeroValue` | Revert Condition | **Inv 81**: `enterWithNativeToken` reverts if `msg.value` is zero — either WETH deposit reverts or `_enter` reverts on zero amount | | ✓ |
| B-83 | `enterWithNativeTokenRevertsOverflow` | Revert Condition | **Inv 83**: `enterWithNativeToken` reverts if `msg.value` exceeds `type(uint128).max` — `SafeCast.toUint128` enforces the bound | | ✓ |
| B-3 | `noAdapterImpliesNotStaked` | Parametric | Cross-variable consistency: if `adapter == address(0)`, then `isStakedInAdapter` must be false (inductive) | | ✓ |
| B-4 | `validVaultHasNonZeroTargetPrice` | Parametric | Cross-variable consistency: existing vault's `targetPrice` can never become zero | | ✓ |
| B-5 | `nextVaultIdOnlyChangedByCreateVault` | Parametric | `nextVaultId` can only be modified by `createVault` — no other function changes it | | ✓ |
| B-6 | `lastSyncedAtMonotonic` | Parametric | `lastSyncedAt` never decreases for existing vaults (time moves forward) | | ✓ |
| B-9 | `lastSyncedPriceMonotonicWhenSettled` | Parametric | Once SETTLED (`lastSyncedPrice >= targetPrice`), price cannot drop below target | | ✓ |
| B-10 | `enterDecreasesCallerBalance` | Integrity | CVL Ghost ERC20: `enter` on non-adapter vault decreases caller's token balance by exactly the deposit amount | | ✓ |
| B-11 | `enterIncreasesContractBalance` | Integrity | CVL Ghost ERC20: `enter` on non-adapter vault increases contract's token balance by exactly the deposit amount | | ✓ |

### SablierEscrow (29 properties)

Order state machine, monotonic flags, parametric access control, conservation on fill, input validation, and cross-variable consistency.

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
| E-1 | `onlyComptrollerCanChangeTradeFee` | Access Control | **Inv 48**: Parametric state-change — if `tradeFee` changes, `msg.sender` must be comptroller | ✓ | ✓ |
| E-2 | `onlyComptrollerCanChangeNativeToken` | Access Control | **Inv 48**: Parametric state-change — if `nativeToken` changes, `msg.sender` must be comptroller | ✓ | ✓ |
| E-46a | `createOrderRejectsNativeSellToken` | Revert Condition | **Inv 46**: `createOrder` reverts if `sellToken` equals `nativeToken` | | ✓ |
| E-46b | `createOrderRejectsNativeBuyToken` | Revert Condition | **Inv 46**: `createOrder` reverts if `buyToken` equals `nativeToken` | | ✓ |
| E-76 | `createOrderRevertsSameToken` | Revert Condition | **Inv 76**: `createOrder` reverts if `sellToken` and `buyToken` are the same address | | ✓ |
| E-77 | `createOrderRevertsSellAmountZero` | Revert Condition | **Inv 77**: `createOrder` reverts if `sellAmount` is zero | | ✓ |
| E-78 | `createOrderRevertsMinBuyAmountZero` | Revert Condition | **Inv 78**: `createOrder` reverts if `minBuyAmount` is zero | | ✓ |
| E-79 | `zeroExpiryOrderNeverExpires` | Integrity | **Inv 79**: An order with `expiryTime` of zero returns OPEN status regardless of `block.timestamp` — zero is a sentinel for orders that never expire | | ✓ |
| E-80 | `fillOrderRevertsInsufficientBuyAmount` | Revert Condition | **Inv 80**: `fillOrder` reverts if `buyAmount` is less than the order's `minBuyAmount` | | ✓ |
| E-3 | `nextOrderIdOnlyChangedByCreateOrder` | Parametric | `nextOrderId` can only be modified by `createOrder` — no other function changes it | | ✓ |
| E-4 | `validOrderHasNonZeroSeller` | Parametric | Cross-variable consistency: existing order's `seller` can never become zero | | ✓ |
| E-5 | `filledOrderCannotBeCancelled` | Revert Condition | Once `wasFilled` is true, `cancelOrder` must revert | | ✓ |
| E-6 | `cancelledOrderCannotBeFilled` | Revert Condition | Once `wasCanceled` is true, `fillOrder` must revert | | ✓ |
| E-7 | `cancelOrderReturnsSellAmount` | Conservation | **Inv 36**: CVL Ghost ERC20 — cancel returns full `sellAmount` to seller (concrete balance verification) | | ✓ |
| E-8 | `fillOrderSellTokenConservation` | Conservation | **Inv 42 (concrete)**: CVL Ghost ERC20 — escrow sell token balance decreases by exactly `sellAmount` on fill | | ✓ |

### SablierLidoAdapter (21 active, 1 n/a properties)

Adapter yield fee immutability, parameter bounds, parametric access control, WETH distribution conservation, Lido withdrawal, and cross-variable consistency.

| ID&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Name | Type | Description | Audit | Mitig. |
|:------|:----------------------------------------|:----------|:-------------------------------------------------|:---:|:---:|
| L-C1 | `userWstETHClearedAfterRedemption` | Integrity | **Inv 29 / C-1 FIXED**: `processRedemption` (renamed from `calculateAmountToTransferWithYield`) now includes `delete _userWstETH[vaultId][user]`, clearing the user's wstETH balance after computing WETH payout — prevents repeated redemption via share recycling | ✗ | ✓ |
| L-L7 | `wethDistributionConservation` | Conservation | **Inv 24 / L-7**: `processRedemption` uses floor division — sum of individual WETH shares < total WETH received, leaving dust stuck in contract with no recovery mechanism | ✗ | ✗ |
| L-31 | `vaultYieldFeeImmutable` | Parametric | Once a vault's yield fee is set via `registerVault`, no function can modify it | ✓ | ✓ |
| LA-1 | `onlyComptrollerCanChangeFeeOnYield` | Access Control | **Inv 48**: Parametric state-change — if `feeOnYield` changes, `msg.sender` must be comptroller | ✓ | ✓ |
| LA-2 | `onlyComptrollerCanChangeSlippageTolerance` | Access Control | **Inv 48**: Parametric state-change — if `slippageTolerance` changes, `msg.sender` must be comptroller | ✓ | ✓ |
| LA-3 | `onlySablierBobCanChangeTotalWstETH` | Access Control | **Inv 49**: Parametric state-change — if `_vaultTotalWstETH` changes, `msg.sender` must be `SABLIER_BOB` | ✓ | ✓ |
| LA-4 | `onlySablierBobCanChangeUserWstETH` | Access Control | **Inv 49**: Parametric state-change — if `_userWstETH` changes for any vault/user, `msg.sender` must be `SABLIER_BOB` | ✓ | ✓ |
| ~~L-49c~~ | ~~`unstakeForUserOnlySablierBob`~~ | ~~Access Control~~ | ~~`unstakeForUserWithinGracePeriod` reverts if `msg.sender` is not `SABLIER_BOB`~~ | ✓ | N/A |
| L-53 | `feeOnYieldNotTooHigh` | Parametric | `feeOnYield` never exceeds `MAX_FEE` after any state change | ✓ | ✓ |
| L-54 | `slippageToleranceNotTooHigh` | Parametric | `slippageTolerance` never exceeds `MAX_SLIPPAGE_TOLERANCE` after any state change | ✓ | ✓ |
| L-M3 | `nonZeroShareTransferMovesWstETH` | Integrity | **Inv 32 / M-3 FIXED**: `updateStakedTokenBalance` now reverts when the computed wstETH transfer amount is zero — prevents unbacked share transfers from floor division truncation | ✗ | ✓ |
| LA-5 | `onlyComptrollerCanChangeLidoRequestIds` | Access Control | **Inv 55**: Parametric state-change — if `_lidoWithdrawalRequestIds` changes, `msg.sender` must be comptroller | | ✓ |
| L-57a | `lidoWithdrawalRequestIdsMonotonic` | Parametric | **Inv 57, 74**: Once Lido withdrawal request IDs are set for a vault, no function can clear them — Curve path permanently blocked | | ✓ |
| L-57b | `requestLidoWithdrawalIdempotent` | Revert Condition | **Inv 57, 75**: `requestLidoWithdrawal` reverts if Lido withdrawal already requested for the vault | | ✓ |
| L-57c | `curvePathBlocksLidoPath` | Parametric | **Inv 57**: If a vault was unstaked via Curve, no function can set Lido withdrawal request IDs for that vault | | ✓ |
| L-28 | `vaultTotalWstETHEqualsSumUserWstETH` | Parametric | **Inv 28**: `_vaultTotalWstETH[vaultId]` equals the ghost sum of all `_userWstETH[vaultId][user]` after any function except `processRedemption` (which intentionally desyncs — total is snapshot denominator for proportional WETH distribution) | | ✓ |
| L-71 | `updateStakedTokenBalancePreservesTotal` | Conservation | **Inv 71**: `updateStakedTokenBalance` does not change `_vaultTotalWstETH` — transferring wstETH between users is a net-zero operation on the vault total | | ✓ |
| L-72 | `processRedemptionConservation` | Conservation | **Inv 72**: `transferAmount + feeAmountDeductedFromYield` equals the user's proportional WETH share (`_userWstETH * _wethReceivedAfterUnstaking / _vaultTotalWstETH`) | | ✓ |
| L-73 | `noPayoutWithoutUnstaking` | Integrity | **Inv 73**: `processRedemption` returns zero `transferAmount` and zero fee when `_wethReceivedAfterUnstaking` is zero — no payout possible before unstaking occurs | | ✓ |
| LA-6 | `vaultYieldFeeBounded` | Parametric | Per-vault yield fee never exceeds `MAX_FEE` — snapshotted from `feeOnYield` which is bounded by Inv 53 | | ✓ |
| LA-7 | `wethReceivedOnlyChangedByUnstake` | Parametric | `_wethReceivedAfterUnstaking` can only be modified by `unstakeFullAmount` | | ✓ |
| LA-8 | `wethReceivedImmutableOnceSet` | Parametric | Once `_wethReceivedAfterUnstaking` is set (non-zero), no function other than `unstakeFullAmount` can change it | | ✓ |

## Assumptions - Safe

The following `require` statements are used in specs to constrain the prover to realistic states. Each is annotated with `"safe: ..."` in the spec source.

| Assumption | Used In | Justification |
|------------|---------|---------------|
| `vaultId < nextVaultId()` | B-2a–B-23, B-25, B-30, B-58–B-83 | Only valid vault IDs that have been created |
| `orderId < nextOrderId()` | E-33–E-45, E-79, E-80 | Only valid order IDs that have been created |
| `targetPrice > 0` | B-2a, B-4, B-14, B-15, B-63, B-81 | Valid vaults always have non-zero target price (set in `createVault`) |
| `expiry > 0` | B-2b, B-15 | Valid vaults always have non-zero expiry (enforced by `createVault`) |
| `lastPrice >= targetPrice` | B-2a | Precondition for SETTLED state |
| `lastPrice < targetPrice` | B-4, B-81 | Precondition for ACTIVE state (price below target) |
| `e.block.timestamp < expiry` | B-4, B-81 | Precondition for non-expired vault |
| `e.block.timestamp >= expiry` | B-2b | Precondition for EXPIRED state |
| `token != 0` | B-13 | Non-zero token to reach the expiry check (skips earlier token-zero revert) |
| `e.block.timestamp <= max_uint40` | B-13 | Solidity casts `block.timestamp` to `uint40` at L113; without this, the prover exploits wrap-around (year 36,812 unreachable) |
| `expiry <= e.block.timestamp` | B-13 | Testing that creating vault with past/current expiry reverts |
| `ghostOracleAnswer > 0` | B-14 | Oracle reports a positive answer |
| `ghostOracleAnswer >= targetPrice` | B-14 | Oracle price at or above target price |
| `ghostOracleAnswer < targetPrice` | B-4 | Models oracle not reporting settlement price — ensures vault stays ACTIVE after internal sync |
| `lastPrice >= targetPrice \|\| timestamp >= expiry` | B-15a/b/c, B-63 | Vault is in non-ACTIVE state (SETTLED or EXPIRED) |
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
| `native != 0` | B-46, E-46a, E-46b | `nativeToken` must be set for the native token check to be meaningful |
| `token == native` | B-46 | Attempting to create vault with native token — testing revert |
| `sellToken == native` | E-46a | Attempting to use native token as sell token — testing revert |
| `buyToken == native` | E-46b | Attempting to use native token as buy token — testing revert |
| `sellToken != native && sellToken != 0` | E-46b | Bypass earlier reverts to reach the buy token check |
| `getTotalYieldBearingTokenBalance == ghostSum` | L-28 | Inductive hypothesis — total equals sum before function call |
| `transferFeesToComptroller` filtered | L-28, L-57a, L-57c | Low-level `call{value}("")` triggers HAVOC_ALL on adapter storage — false positive since it only sends ETH |
| `token == 0` | B-58 | Token must be zero address to test the revert condition |
| `targetPrice == 0` | B-59 | Target price must be zero to test the revert condition |
| `getAdapter(vaultId) != 0` | B-63 | Vault must have an adapter to test the adapter-specific msg.value revert |
| `e.msg.value > 0` | B-63 | msg.value must be positive to test the revert condition |
| `e.msg.sender != shareToken` | B-64 | Caller must not be the share token to test access control |
| `e.msg.value == 0` | B-25, B-58, B-59, B-64, S-70a, S-70b, E-76–E-80 | Non-payable functions — prevents Solidity ABI revert on msg.value > 0 |
| `sellToken == buyToken` | E-76 | Tokens must be the same to test the same-token revert |
| `sellAmount == 0` | E-77 | Sell amount must be zero to test the revert condition |
| `minBuyAmount == 0` | E-78 | Min buy amount must be zero to test the revert condition |
| `getExpiryTime(orderId) == 0` | E-79 | Order must have zero expiry to test never-expires semantics |
| `e.block.timestamp > max_uint40` | E-79 | Arbitrarily large timestamp to prove zero-expiry orders remain OPEN regardless |
| `buyAmount < minBuyAmount` | E-80 | Buy amount must be below minimum to test the revert condition |
| `e.msg.value > max_uint128` | B-83 | msg.value must exceed uint128 max to test SafeCast overflow revert |
| `enterWithNativeToken` filtered | B-10, B-12 | `enterWithNativeToken` calls `_syncPriceFromOracle` via `_enter` (authorized price modifier); NONDET on WETH deposit prevents ETH balance tracking (ETH correctly forwarded on all paths) |
| `getWethReceivedAfterUnstaking == 0` | L-73 | Vault must not have been unstaked to test the zero-payout condition |

## Assumptions - Proved

The following invariant is used as a precondition via `requireInvariant` in preserved blocks:

| Invariant | Used In | Purpose |
|-----------|---------|---------|
| `totalSupplyIsSumOfBalances` (S-18) | S-18 preserved blocks | Required for induction step: confirms balance bounds hold so that OZ unchecked arithmetic in `_update()` cannot wrap |

---

## Verification Results

Final prover run URLs (Certora Prover v8.8.1). All 88 active properties verified; the 2 expected violations correspond to documented bugs (L-7 and L-8).

| Spec | Result | Prover URL |
|------|--------|-----------|
| BobVaultShare | All 7 rules pass | [Prover Link](https://prover.certora.com/output/4319676/477da5eebc26496d9fa5d51fe96630e0?anonymousKey=f28f0b20f04448887671cff196af85e46c1dbef2) |
| SablierBob | All 33 rules pass | [Prover Link](https://prover.certora.com/output/4319676/7b9c436f3a594fdb86a97c889aab7788?anonymousKey=a07ed44e8701ad41cc8c19c7e4731eaebfb27470) |
| SablierEscrow | 29 pass, 1 expected fail (E-45/L-8) | [Prover Link](https://prover.certora.com/output/4319676/9244dc8c32fd459fa71f6cf41e93c0d5?anonymousKey=17d3d71e8cf701e695ebedc088fae805070df01a) |
| SablierLidoAdapter | 21 pass, 1 expected fail (L-L7) | [Prover Link](https://prover.certora.com/output/4319676/af0985c8557e4b7d8943b46be37af720?anonymousKey=c6c2689a37da787b1aeeb2d4619b8c8c036237a7) |

## Setup and Execution

The Certora Prover can be run either remotely (using Certora's cloud infrastructure) or locally (building from source); both modes share the same initial setup steps.

### Common Setup (Steps 1-4)

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
