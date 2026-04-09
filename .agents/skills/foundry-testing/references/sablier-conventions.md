# Sablier Foundry Test Conventions

Sablier-specific testing patterns. Find code examples in the actual codebase.

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

______________________________________________________________________

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

______________________________________________________________________

## Revert Helper Patterns

| Helper                          | Purpose                       |
| ------------------------------- | ----------------------------- |
| `expectRevert_Null(callData)`   | Test null stream handling     |
| `expectRevert_DEPLETEDStatus()` | Test depleted stream handling |
| `expectRevert_DelegateCall()`   | Test delegate call protection |

______________________________________________________________________

## Sablier BTT Modifiers

| Modifier                   | Purpose                            |
| -------------------------- | ---------------------------------- |
| `givenSTREAMINGStatus()`   | Warp to 26% through stream         |
| `givenNotDEPLETEDStatus()` | Warp to start time                 |
| `whenStreamCancelable()`   | Document cancelable path (empty)   |
| `whenStreamTransferable()` | Document transferable path (empty) |

______________________________________________________________________

## Hook Mock Types

| Mock                       | Behavior                    |
| -------------------------- | --------------------------- |
| `RecipientGood`            | Returns correct selector    |
| `RecipientReverting`       | Reverts on hook call        |
| `RecipientInvalidSelector` | Returns `0xDEADBEEF`        |
| `RecipientReentrant`       | Attempts withdrawal reentry |

______________________________________________________________________

## Merkle Campaign Mocks

| Mock                                 | Behavior                       |
| ------------------------------------ | ------------------------------ |
| `MerkleMock`                         | Returns `true` for IS_SABLIER  |
| `MerkleMockReverting`                | Reverts on lowerMinFeeUSD      |
| `MerkleMockWithFalseIsSablierMerkle` | Returns `false` for IS_SABLIER |

______________________________________________________________________

## Defaults Contract Patterns

| Method                  | Returns                       |
| ----------------------- | ----------------------------- |
| `durations()`           | LockupLinear.Durations struct |
| `lockupAmounts()`       | Lockup.Amounts struct         |
| `lockupTimestamps()`    | Lockup.Timestamps struct      |
| `createWithDurations()` | Full create params struct     |

______________________________________________________________________

## Assertion Helpers

| Assertion                                | Compares                                |
| ---------------------------------------- | --------------------------------------- |
| `assertEq(Lockup.Amounts, ...)`          | deposited, withdrawn, refunded          |
| `assertEq(Lockup.Timestamps, ...)`       | start, end                              |
| `assertEq(LockupDynamic.Segment[], ...)` | amount, exponent, timestamp per segment |

______________________________________________________________________

## Fuzzer Helpers

| Helper                       | Purpose                               |
| ---------------------------- | ------------------------------------- |
| `fuzzDynamicStreamAmounts()` | Bound segment amounts, return deposit |
| `fuzzSegmentTimestamps()`    | Fuzz timestamps preserving order      |

______________________________________________________________________

## Invariant Examples

| Invariant                        | Property                    |
| -------------------------------- | --------------------------- |
| `invariant_DepositedGteStreamed` | deposited ≥ streamed always |
| `invariant_WithdrawnLteStreamed` | withdrawn ≤ streamed always |

______________________________________________________________________

## Commands

```bash
just lockup::test                              # All tests
just lockup::test --match-path "tests/fork/**" # Fork tests only
just lockup::test-bulloak                      # Verify BTT alignment
just lockup::test-optimized                    # Optimized profile
just lockup::coverage                          # Coverage report
```
