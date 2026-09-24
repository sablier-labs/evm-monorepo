---
name: foundry-testing
description:
  Write Foundry tests, bulloak BTT tree specs, and Solidity scripts. Trigger phrases - foundry testing, write test,
  write a tree, BTT spec, bulloak tree, Branching Tree Technique, fuzz test, fork test, invariant test, deploy script,
  gas benchmark, coverage, or when working in tests/ or scripts/ directories.
---

# Foundry Testing & Script Skill

Rules and patterns for Foundry tests, bulloak `.tree` specs, and scripts. Find examples in the actual codebase.

## Bundled References

| Reference                           | Content                                   | When to Read                   |
| ----------------------------------- | ----------------------------------------- | ------------------------------ |
| `references/btt-examples.md`        | Complete tree and generated test examples | When learning BTT syntax       |
| `references/test-infrastructure.md` | Constants, defaults, mocks                | When setting up tests          |
| `references/cheat-codes.md`         | Common cheatcode patterns                 | When using vm cheatcodes       |
| `references/invariant-patterns.md`  | Handlers, stores, invariants              | When writing invariant tests   |
| `references/gas-benchmarking.md`    | Snapshot, profiling, CI                   | When measuring gas performance |
| `references/sablier-conventions.md` | Sablier BTT terminology and test patterns | When working in Sablier repos  |

---

## Test Types

| Type        | Directory                     | Naming             | Purpose                      |
| ----------- | ----------------------------- | ------------------ | ---------------------------- |
| Integration | `tests/integration/concrete/` | `*.t.sol`          | BTT-based concrete tests     |
| Fuzz        | `tests/integration/fuzz/`     | `*.t.sol`          | Property-based testing       |
| Fork        | `tests/fork/`                 | `*.t.sol`          | Mainnet state testing        |
| Invariant   | `tests/invariant/`            | `Invariant*.t.sol` | Stateful protocol properties |
| Scripts     | `scripts/solidity/`           | `*.s.sol`          | Deployment/initialization    |

---

## 1. Integration Tests (Concrete, BTT)

Concrete tests are specified as [bulloak](https://github.com/alexfertel/bulloak) `.tree` files using the Branching Tree
Technique, then scaffolded into `.t.sol` files. Install bulloak with `cargo install bulloak` if missing.

### Workflow

1. Write the tree at `tests/integration/concrete/{function-name}/{functionName}.tree`. Packages with several contracts
   nest one more level, e.g. `lockup/tests/integration/concrete/lockup/cancel/cancel.tree`.
2. Scaffold the test: `bulloak scaffold -wf --skip-modifiers --format-descriptions <path/to/file.tree>`
   - `--skip-modifiers`: modifiers live in the shared `Modifiers.sol`, not in each test.
   - `--format-descriptions`: capitalizes each branch and appends a period in the generated comments.
3. Implement the test bodies (rules below).
4. Check alignment: `bulloak check --skip-modifiers <path/to/file.tree>`, or `just <pkg>::test-bulloak` for a whole
   package. Fix the tree or the test until they match.

### File Rules

1. Directory name is kebab-case: `createFlowStream` → `create-flow-stream/`.
2. Tree file is `{functionName}.tree`; test file is `{functionName}.t.sol`.
3. Single-tree root and contract name: `{FunctionName}_Integration_Concrete_Test`.
4. Multiple trees in one file: each root is `Contract::function`, all sharing the same contract name (e.g.
   `Foo::hashPair`, `Foo::min`).

### Tree Syntax

```
FunctionName_Integration_Concrete_Test
├── when delegate call
│  └── it should revert
└── when no delegate call
   ├── given null
   │  └── it should revert
   └── given not null
      └── it should ...
```

| Keyword | Purpose                                      |
| ------- | -------------------------------------------- |
| `when`  | Conditional branch (user input or timestamp) |
| `given` | Pre-condition contract state branch          |
| `it`    | Action/assertion (leaf node)                 |

- `when` and `given` are interchangeable to bulloak; a condition with nested branches becomes a modifier.
- Children of an `it` action are action descriptions.
- Use `├` and `└` for branches. Child symbols align with the tail of the parent's `├──`/`└──`: **3 spaces**, not 4.
- **No trailing periods** on branches; `--format-descriptions` adds them.
- Put event names in braces: `it should emit {Transfer} and {MetadataUpdate} events`.

### Tree Best Practices

1. **Order guards first**: delegate call → existence (`given null`) → state → caller → input validation → business
   logic.
2. **Use concise, consistent terms**: `given null` / `given not null`, `when caller {role}`, `when amount {condition}`.
3. **Group related conditions** under a shared parent (e.g. all non-owner caller cases together).
4. **Enumerate every side effect** in the happy-path leaf:

   ```
   └── it should make the withdrawal
      ├── it should reduce the entry balance by the withdrawn amount
      ├── it should update the entry state
      └── it should emit {Transfer}, {Withdraw} and {MetadataUpdate} events
   ```

### Test Naming

| Pattern                       | Usage           |
| ----------------------------- | --------------- |
| `test_RevertWhen_{Condition}` | Revert on input |
| `test_RevertGiven_{State}`    | Revert on state |
| `test_When{Condition}`        | Success path    |
| `test_Given{State}`           | Success path    |

### Test Rules

1. **Leaf comments** - each test starts with the leaf text as a comment: `// It should revert.`
2. **Stack modifiers** to document the BTT path (modifiers are often empty - they only document the path).
3. **No self-named modifier** - never add a modifier matching the test's own name
   (`test_WhenAmountNotZero() whenAmountNotZero` is redundant).
4. **Expect events BEFORE action** - `vm.expectEmit()` then call the function. Every event must be expected, with all
   parameters, in at least one test.
5. **Assert state AFTER action** - check state changes after the function executes.
6. **Use revert helpers** for common patterns (`expectRevert_DelegateCall`, `expectRevert_Null`).
7. **Describe assertions** - `assertEq(actual, expected, "description")`.

### Mock Rules

1. Place all mocks in `tests/mocks/`
2. One mock per scenario (not one mega-mock)
3. Naming: `*Good`, `*Reverting`, `*InvalidSelector`, `*Reentrant`

---

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

---

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

---

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

---

## 5. Solidity Scripts

### Rules

1. Inherit `BaseScript` from `@sablier/evm-utils/src/tests/BaseScript.sol` and apply its `broadcast` modifier to `run`.
2. The broadcaster is `ETH_FROM` when set, otherwise index 0 of `MNEMONIC`; scripts never read `PRIVATE_KEY`.
3. Deterministic scripts deploy with `new Foo{ salt: SALT }(...)`. `SALT` encodes the chain ID and `getVersion()` (the
   package version), so override `getVersion()` only to pin a release.
4. Read chain-dependent inputs from `BaseScript` helpers such as `getAdmin()` and `getComptroller()`; never hardcode
   them.
5. Return the deployed contracts from `run`.

Running deployments (simulation, broadcast, verification, resume) is covered by the `protocol-deployment` skill.

---

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

---

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

---

## Best Practices Summary

1. Use constants from `Defaults`/`Constants` - never hardcode
2. Specialized mocks - one per scenario, all in `tests/mocks/`
3. Modifiers in `Modifiers.sol` - centralize BTT path modifiers
4. Label addresses with `vm.label()` for traces
5. Events before actions - `vm.expectEmit()` then call
6. Bound before assume - more efficient

## Completion

Finish only after the new or changed tests pass with a narrow `just <pkg>::test --match-path <path>` (or `--match-test`)
run, and, when a `.tree` file or BTT test changed, `just <pkg>::test-bulloak` passes for every touched package. Report
the exact commands and results.

## External References

- [Foundry Book](https://getfoundry.sh)
- [Bulloak README](https://github.com/alexfertel/bulloak/blob/main/README.md)
