# Test Infrastructure Reference

Rules for test utilities and setup. Find examples in the actual codebase.

## Constants

### Naming Conventions

| Pattern       | Usage                       | Example                  |
| ------------- | --------------------------- | ------------------------ |
| `*_TIME`      | Absolute timestamps         | `START_TIME`, `END_TIME` |
| `*_DURATION`  | Relative durations          | `CLIFF_DURATION`         |
| `*_AMOUNT`    | Token amounts (18 decimals) | `DEPOSIT_AMOUNT`         |
| `*_AMOUNT_6D` | Token amounts (6 decimals)  | `DEPOSIT_AMOUNT_6D`      |
| `WARP_*`      | Time warp targets           | `WARP_26_PERCENT`        |
| `*_COUNT`     | Counts/sizes                | `SEGMENT_COUNT`          |

______________________________________________________________________

## Defaults Contract

### Parameter Patterns

| Type            | Pattern                             |
| --------------- | ----------------------------------- |
| Simple structs  | Return directly with constants      |
| User-dependent  | Reference `users` struct from setUp |
| Token-dependent | Reference `token` set during setUp  |
| Arrays          | Build using helper contracts        |

______________________________________________________________________

## User Roles

| User        | Purpose                                   |
| ----------- | ----------------------------------------- |
| `alice`     | Generic third party                       |
| `eve`       | Malicious actor for unauthorized calls    |
| `operator`  | Approved operator for testing permissions |
| `recipient` | Default entry recipient                   |
| `sender`    | Default entry sender/funder               |

______________________________________________________________________

## Modifiers

### Categories

| Category        | Description                            |
| --------------- | -------------------------------------- |
| Empty modifiers | Document BTT path only                 |
| Setup modifiers | Perform state changes (warps, callers) |
| Parameterized   | Accept parameters for flexible setup   |

### Rules

1. Centralize all modifiers in `Modifiers.sol`
2. Inherit from `Fuzzers` for bounding helpers
3. Use `setMsgSender()` instead of raw `vm.prank()`

______________________________________________________________________

## Fuzzer Helpers

### Rules

1. Create typed bound helpers: `boundUint128`, `boundUint40`
2. Bound in dependency order (independent params first)
3. For arrays, fuzz timestamps preserving order
4. For amounts, ensure first element non-zero

______________________________________________________________________

## Base Test Setup Order

1. Call parent setUp
2. Deploy helper/mock contracts
3. Label contracts for traces (`vm.label`)
4. Deploy and configure defaults
5. Deploy protocol contracts
6. Create users with approvals
7. Configure permissions
8. Set default caller
9. Warp to realistic time

______________________________________________________________________

## Mock Naming Convention

| Pattern                 | Usage                  |
| ----------------------- | ---------------------- |
| `*Good`                 | Happy path mock        |
| `*Reverting`            | Mock that reverts      |
| `*InvalidSelector`      | Returns wrong selector |
| `*Reentrant`            | Attempts reentrancy    |
| `*InterfaceIDIncorrect` | Wrong interface ID     |
| `*InterfaceIDMissing`   | Missing interface      |

### Mock Rules

1. Place all mocks in `tests/mocks/`
2. One mock per scenario (not mega-mocks)
3. Name clearly describes behavior

______________________________________________________________________

## Integration Test Base

### Revert Helper Pattern

Create helpers for common revert tests:

- `expectRevert_DelegateCall(callData)` - Test delegate call protection
- `expectRevert_Null(callData)` - Test null entry handling

### Rules

1. Initialize all entry IDs in `initializeDefaultEntries()`
2. Use `ids.nullEntry = 1729` for non-existent entry
3. Create helpers for repeated assertion patterns
