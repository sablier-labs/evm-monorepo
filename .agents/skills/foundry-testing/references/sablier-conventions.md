# Sablier Test Conventions

Sablier-specific BTT and Foundry testing patterns. Find code examples in the actual codebase.

## Test Directory Structure

```
tests/
├── mocks/                    # ISablierLockupRecipient mocks, NFTDescriptorMock
├── integration/
│   ├── concrete/             # BTT-based tests (function.tree + function.t.sol)
│   └── fuzz/
├── fork/
│   └── tokens/               # Per-token fork tests (USDC, USDT, DAI)
└── invariant/
    ├── handlers/             # LockupHandler, FlowHandler
    └── stores/               # LockupStore, FlowStore
```

---

## BTT Terminology

| Concept              | BTT Branch                  |
| -------------------- | --------------------------- |
| Stream doesn't exist | `given null`                |
| Stream exists        | `given not null`            |
| Stream depleted      | `given stream depleted`     |
| Stream not depleted  | `given stream not depleted` |
| Stream cancelable    | `given stream cancelable`   |
| Caller is sender     | `when caller sender`        |
| Caller is recipient  | `when caller recipient`     |
| Caller is unknown    | `when caller unknown`       |

---

## BTT Guard Condition Order

```
FunctionName_Integration_Concrete_Test
├── when delegate call
│  └── it should revert
└── when no delegate call
   ├── given null
   │  └── it should revert
   └── given not null
      ├── given stream depleted
      │  └── it should revert
      └── given stream not depleted
         ├── when caller unknown
         │  └── it should revert
         └── when caller authorized
            └── ...
```

---

## BTT Happy Path Examples

### Flow Withdraw

```
└── it should make the withdrawal
   ├── it should reduce the stream balance by the withdrawn amount
   ├── it should reduce the aggregate amount by the withdrawn amount
   ├── it should update snapshot debt
   ├── it should update snapshot time to current time
   └── it should emit {Transfer}, {WithdrawFromFlowStream} and {MetadataUpdate} events
```

### Lockup Withdraw

```
└── it should make the withdrawal
   ├── it should mark the stream as depleted
   ├── it should make the stream not cancelable
   ├── it should update the withdrawn amount
   ├── it should reduce the aggregate amount
   └── it should emit {Transfer}, {WithdrawFromLockupStream} and {MetadataUpdate} events
```

### Lockup Cancel

```
└── it should cancel the stream
   ├── it should mark the stream as canceled
   ├── it should make the stream not cancelable
   ├── it should set the refunded amount
   ├── it should refund the sender
   ├── it should reduce the aggregate amount
   ├── it should emit {Transfer} event
   └── it should emit {CancelLockupStream} event
```

### Airdrop Claim

```
└── it should claim
   ├── it should mark the index as claimed
   ├── it should create the lockup stream
   └── it should emit {Claim} event
```

---

## BTT Model-Specific Trees

When testing model-specific behavior (Linear, Dynamic, Tranched):

```
StreamedAmountOf_Integration_Concrete_Test
├── given model LL
│  ├── when current time before cliff
│  │  └── it should return zero
│  └── when current time after cliff
│     └── it should return correct streamed amount
├── given model LD
│  └── ...
└── given model LT
   └── ...
```

---

## StreamIds Struct

| Field                            | Purpose                    |
| -------------------------------- | -------------------------- |
| `defaultStream`                  | Standard test stream       |
| `notAllowedToHookStream`         | Hook not allowlisted       |
| `notCancelableStream`            | Non-cancelable stream      |
| `notTransferableStream`          | Non-transferable stream    |
| `nullStream`                     | Non-existent (1729)        |
| `recipientGoodStream`            | Good hook recipient        |
| `recipientInvalidSelectorStream` | Invalid selector recipient |
| `recipientReentrantStream`       | Reentrant recipient        |
| `recipientRevertStream`          | Reverting recipient        |

---

## Revert Helper Patterns

| Helper                          | Purpose                       |
| ------------------------------- | ----------------------------- |
| `expectRevert_Null(callData)`   | Test null stream handling     |
| `expectRevert_DEPLETEDStatus()` | Test depleted stream handling |
| `expectRevert_DelegateCall()`   | Test delegate call protection |

---

## Sablier BTT Modifiers

| Modifier                   | Purpose                            |
| -------------------------- | ---------------------------------- |
| `givenSTREAMINGStatus()`   | Warp to 26% through stream         |
| `givenNotDEPLETEDStatus()` | Warp to start time                 |
| `whenStreamCancelable()`   | Document cancelable path (empty)   |
| `whenStreamTransferable()` | Document transferable path (empty) |

---

## Hook Mock Types

| Mock                       | Behavior                    |
| -------------------------- | --------------------------- |
| `RecipientGood`            | Returns correct selector    |
| `RecipientReverting`       | Reverts on hook call        |
| `RecipientInvalidSelector` | Returns `0xDEADBEEF`        |
| `RecipientReentrant`       | Attempts withdrawal reentry |

---

## Merkle Campaign Mocks

| Mock                                 | Behavior                       |
| ------------------------------------ | ------------------------------ |
| `MerkleMock`                         | Returns `true` for IS_SABLIER  |
| `MerkleMockReverting`                | Reverts on lowerMinFeeUSD      |
| `MerkleMockWithFalseIsSablierMerkle` | Returns `false` for IS_SABLIER |

---

## Defaults Contract Patterns

| Method                  | Returns                       |
| ----------------------- | ----------------------------- |
| `durations()`           | LockupLinear.Durations struct |
| `lockupAmounts()`       | Lockup.Amounts struct         |
| `lockupTimestamps()`    | Lockup.Timestamps struct      |
| `createWithDurations()` | Full create params struct     |

---

## Assertion Helpers

| Assertion                                | Compares                                |
| ---------------------------------------- | --------------------------------------- |
| `assertEq(Lockup.Amounts, ...)`          | deposited, withdrawn, refunded          |
| `assertEq(Lockup.Timestamps, ...)`       | start, end                              |
| `assertEq(LockupDynamic.Segment[], ...)` | amount, exponent, timestamp per segment |

---

## Fuzzer Helpers

| Helper                       | Purpose                               |
| ---------------------------- | ------------------------------------- |
| `fuzzDynamicStreamAmounts()` | Bound segment amounts, return deposit |
| `fuzzSegmentTimestamps()`    | Fuzz timestamps preserving order      |

---

## Invariant Examples

| Invariant                        | Property                    |
| -------------------------------- | --------------------------- |
| `invariant_DepositedGteStreamed` | deposited ≥ streamed always |
| `invariant_WithdrawnLteStreamed` | withdrawn ≤ streamed always |

---

## Monorepo Import Resolution

Resolve `@sablier/evm-utils/` imports from `utils/`, not `node_modules/`. See "Monorepo Import Resolution" in the
`solidity-coding` skill's `references/sablier-conventions.md`.

---

## Commands

```bash
just lockup::test                              # All tests
just lockup::test --match-path "tests/fork/**" # Fork tests only
just lockup::test-bulloak                      # Verify BTT alignment
just lockup::test-optimized                    # Optimized profile
just lockup::coverage                          # Coverage report
```
