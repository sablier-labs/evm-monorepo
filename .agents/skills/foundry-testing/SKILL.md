---
name: foundry-testing
user-invocable: true
description: Write Foundry-based tests and scripts. Trigger phrases - foundry testing, write test, fuzz test, fork test, invariant test, deploy script, gas benchmark, coverage, or when working in tests/ or scripts/ directories.
---

# Foundry Testing & Script Skill

Rules and patterns for Foundry tests. Find examples in the actual codebase.

## Bundled References

| Reference                                                           | Content                        | When to Read                   |
| ------------------------------------------------------------------- | ------------------------------ | ------------------------------ |
| `.claude/skills/foundry-testing/references/test-infrastructure.md`  | Constants, defaults, mocks     | When setting up tests          |
| `.claude/skills/foundry-testing/references/cheat-codes.md`          | Common cheatcode patterns      | When using vm cheatcodes       |
| `.claude/skills/foundry-testing/references/invariant-patterns.md`   | Handlers, stores, invariants   | When writing invariant tests   |
| `.claude/skills/foundry-testing/references/formal-verification.md`  | Halmos, Certora, symbolic exec | When proving correctness       |
| `.claude/skills/foundry-testing/references/deployment-scripts.md`   | Script patterns, verification  | When writing deploy scripts    |
| `.claude/skills/foundry-testing/references/deployment-checklist.md` | Pre-mainnet deployment steps   | Before deploying to production |
| `.claude/skills/foundry-testing/references/gas-benchmarking.md`     | Snapshot, profiling, CI        | When measuring gas performance |
| `.claude/skills/foundry-testing/references/sablier-conventions.md`  | Sablier-specific patterns      | When working in Sablier repos  |

______________________________________________________________________

## Test Types

| Type        | Directory                     | Naming             | Purpose                      |
| ----------- | ----------------------------- | ------------------ | ---------------------------- |
| Integration | `tests/integration/concrete/` | `*.t.sol`          | BTT-based concrete tests     |
| Fuzz        | `tests/integration/fuzz/`     | `*.t.sol`          | Property-based testing       |
| Fork        | `tests/fork/`                 | `*.t.sol`          | Mainnet state testing        |
| Invariant   | `tests/invariant/`            | `Invariant*.t.sol` | Stateful protocol properties |
| Scripts     | `scripts/solidity/`           | `*.s.sol`          | Deployment/initialization    |

______________________________________________________________________

## 1. Integration Tests (Concrete)

### Naming Convention

| Pattern                       | Usage           |
| ----------------------------- | --------------- |
| `test_RevertWhen_{Condition}` | Revert on input |
| `test_RevertGiven_{State}`    | Revert on state |
| `test_When_{Condition}`       | Success path    |

### Rules

1. **Stack modifiers** to document BTT path (modifiers are often empty - just document the path)
2. **Expect events BEFORE action** - `vm.expectEmit()` then call function
3. **Assert state AFTER action** - Check state changes after function executes
4. **Use revert helpers** for common patterns (`expectRevert_DelegateCall`, `expectRevert_Null`)
5. **Named parameters in assertions** - `assertEq(actual, expected, "description")`

### Mock Rules

1. Place all mocks in `tests/mocks/`
2. One mock per scenario (not one mega-mock)
3. Naming: `*Good`, `*Reverting`, `*InvalidSelector`, `*Reentrant`

______________________________________________________________________

## 2. Fuzz Tests

### Naming Convention

`testFuzz_{FunctionName}_{Scenario}`

### Rules

1. **Bound before assume** - `_bound()` is more efficient than `vm.assume()`
2. **Bound in dependency order** - Independent params first, then dependent
3. **Never hardcode** params with validation constraints
4. **Document fuzzed scenarios** in NatSpec

### Bounding Pattern

```solidity
// 1. Bound independent params first
cliffDuration = boundUint40(cliffDuration, 0, MAX - 1);

// 2. Bound dependent params based on constraints
totalDuration = boundUint40(totalDuration, cliffDuration + 1, MAX);
```

______________________________________________________________________

## 3. Fork Tests

### Rules

1. Create fork with `vm.createSelectFork("ethereum")`
2. Use `deal()` to give tokens to test users
3. Use `assumeNoBlacklisted()` for USDC/USDT
4. Use `forceApprove()` for non-standard tokens (USDT)

### Token Quirks

| Token           | Issue        | Solution                     |
| --------------- | ------------ | ---------------------------- |
| USDC/USDT       | Blacklist    | `assumeNoBlacklisted()`      |
| USDT            | Non-standard | `forceApprove()`             |
| Fee-on-transfer | Balance diff | Check actual received amount |

______________________________________________________________________

## 4. Invariant Tests

### Architecture

```
tests/invariant/
├── handlers/     # State manipulation (call functions with bounded params)
├── stores/       # State tracking (record totals, IDs)
└── Invariant.t.sol
```

### Rules

1. **Target handlers only** - `targetContract(address(handler))`
2. **Exclude protocol contracts** - `excludeSender(address(vault))`
3. **Use stores** to track totals for invariant assertions
4. **Early return** in handlers if preconditions not met

______________________________________________________________________

## 5. Solidity Scripts

### Rules

1. Inherit from `BaseScript` with `broadcast` modifier
2. Use env vars: `ETH_FROM`, `MNEMONIC`
3. Simulation first, then broadcast

### Commands

```bash
# Simulation
forge script scripts/Deploy.s.sol --sig "run(...)" ARGS --rpc-url $RPC

# Broadcast
forge script scripts/Deploy.s.sol --sig "run(...)" ARGS --rpc-url $RPC --broadcast --verify
```

______________________________________________________________________

## Running Tests

```bash
# By type
forge test --match-path "tests/integration/concrete/**"
forge test --match-path "tests/fork/**"
forge test --match-contract Invariant_Test

# Specific test
forge test --match-test test_WhenCallerRecipient -vvvv

# Fuzz with more runs
forge test --match-test testFuzz_ --fuzz-runs 1000

# Coverage
forge coverage --report lcov
```

______________________________________________________________________

## Debugging

### Verbosity Levels

| Flag     | Shows                       |
| -------- | --------------------------- |
| `-v`     | Logs for failing tests      |
| `-vv`    | Logs for all tests          |
| `-vvv`   | Stack traces for failures   |
| `-vvvv`  | Stack traces + setup traces |
| `-vvvvv` | Full execution traces       |

### Console Logging

```solidity
import { console2 } from "forge-std/console2.sol";

console2.log("value:", someValue);
console2.log("address:", someAddress);
console2.logBytes32(someBytes32);
```

### Debugging Commands

```bash
# Trace specific failing test
forge test --match-test test_MyTest -vvvv

# Gas report for a test
forge test --match-test test_MyTest --gas-report

# Debug in interactive debugger
forge debug --debug tests/MyTest.t.sol --sig "test_MyTest()"

# Inspect storage layout
forge inspect MyContract storage-layout
```

### Debugging Tips

1. **Label addresses** - `vm.label(addr, "Recipient")` for readable traces
2. **Check state with logs** - Add `console2.log` before reverts
3. **Isolate failures** - Run single test with `--match-test`
4. **Compare gas** - Use `--gas-report` to spot unexpected costs
5. **Snapshot comparisons** - Use `vm.snapshot()` / `vm.revertTo()` to isolate state changes

______________________________________________________________________

## Best Practices Summary

1. Use constants from `Defaults`/`Constants` - never hardcode
2. Specialized mocks - one per scenario, all in `tests/mocks/`
3. Modifiers in `Modifiers.sol` - centralize BTT path modifiers
4. Label addresses with `vm.label()` for traces
5. Events before actions - `vm.expectEmit()` then call
6. Bound before assume - more efficient

## External References

- [Foundry Book](https://getfoundry.sh)

______________________________________________________________________

## Example Invocations

Test this skill with these prompts:

1. **Integration test**: "Write a concrete test for `withdraw` that expects `Errors.Flow_Overdraw` when amount exceeds
   balance"
2. **Fuzz test**: "Create a fuzz test for `deposit` that bounds amount between 1 and type(uint128).max"
3. **Fork test**: "Write a fork test for USDC deposits on mainnet with blacklist handling"
4. **Invariant test**: "Create an invariant handler for the `deposit` and `withdraw` functions"
5. **Deploy script**: "Write a deployment script for SablierFlow with verification"
