# Gas Benchmarking

Guide for measuring and tracking gas usage in Sablier contracts.

## Forge Snapshot

### Capture Baseline

```bash
# Create initial snapshot
forge snapshot --snap .gas-snapshot

# Snapshot with specific profile
FOUNDRY_PROFILE=optimized forge snapshot --snap .gas-snapshot-optimized
```

### Compare Changes

```bash
# Compare against baseline
forge snapshot --diff .gas-snapshot

# Check for regressions (fails if any test uses more gas)
forge snapshot --check .gas-snapshot
```

### Output Format

```
testFuzz_Withdraw(uint128) (runs: 256, μ: 45123, ~: 44892)
test_Withdraw_WhenCallerRecipient() (gas: 42156)
```

| Field  | Meaning                    |
| ------ | -------------------------- |
| `runs` | Number of fuzz runs        |
| `μ`    | Mean gas                   |
| `~`    | Median gas                 |
| `gas`  | Exact gas (concrete tests) |

______________________________________________________________________

## Gas Reports

### Inline Gas Report

```bash
# Show gas for each function call
forge test --gas-report
```

### Filtered Report

```bash
# Only show gas for specific contracts
forge test --gas-report --match-contract "SablierLockup"
```

### Report Format

```
| src/SablierLockup.sol:SablierLockup |                 |        |        |        |         |
|-------------------------------------|-----------------|--------|--------|--------|---------|
| Function Name                       | min             | avg    | median | max    | # calls |
| withdraw                            | 23456           | 34567  | 33000  | 89012  | 150     |
| create                              | 156789          | 178901 | 175000 | 234567 | 50      |
```

______________________________________________________________________

## Benchmarking Workflow

### 1. Before Changes

```bash
# Capture baseline
forge snapshot --snap .gas-snapshot-before
```

### 2. Make Changes

Implement your optimization or feature.

### 3. Compare

```bash
# See diff
forge snapshot --diff .gas-snapshot-before

# Save new snapshot if acceptable
forge snapshot --snap .gas-snapshot
```

### 4. Document

Add to PR description:

```markdown
## Gas Changes

| Function | Before  | After   | Diff  |
| -------- | ------- | ------- | ----- |
| withdraw | 34,567  | 32,100  | -7.1% |
| create   | 178,901 | 180,000 | +0.6% |
```

______________________________________________________________________

## Dedicated Gas Tests

### Structure

```
tests/
└── gas/
    └── Gas.t.sol
```

### Pattern

```solidity
contract Gas_Test is Integration_Test {
    /// @dev Benchmarks gas for creating a stream.
    function test_Gas_Create() external {
        uint256 gasBefore = gasleft();
        lockup.createWithTimestampsLL(defaults.createWithTimestamps());
        uint256 gasUsed = gasBefore - gasleft();

        // Log for visibility
        console.log("create gas:", gasUsed);

        // Optional: Assert max gas
        assertLt(gasUsed, 200_000, "create exceeds gas budget");
    }
}
```

### Run Gas Tests

```bash
forge test --match-path "tests/gas/**" --gas-report -vv
```

______________________________________________________________________

## CI Integration

### GitHub Actions Workflow

```yaml
- name: Gas Snapshot
  run: forge snapshot --check .gas-snapshot
  continue-on-error: true # Warn but don't fail

- name: Gas Diff Comment
  if: github.event_name == 'pull_request'
  run: |
    forge snapshot --diff .gas-snapshot > gas-diff.txt
    # Post as PR comment via GitHub API
```

### Pre-commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

# Check for gas regressions
if ! forge snapshot --check .gas-snapshot 2>/dev/null; then
    echo "⚠️  Gas regression detected. Run 'forge snapshot' to update baseline."
    # exit 1  # Uncomment to block commit
fi
```

______________________________________________________________________

## Optimization Targets

### By Function Type

| Function Type   | Target Gas | Notes                    |
| --------------- | ---------- | ------------------------ |
| View (simple)   | < 5,000    | Single storage read      |
| View (computed) | < 20,000   | Multiple reads, math     |
| Create stream   | < 200,000  | Storage writes, NFT mint |
| Withdraw        | < 50,000   | Update + transfer        |
| Cancel          | < 80,000   | Update + 2 transfers     |

### By Operation

| Operation                  | Approximate Cost |
| -------------------------- | ---------------- |
| SSTORE (cold, 0→non-0)     | 22,100           |
| SSTORE (cold, non-0→non-0) | 5,000            |
| SSTORE (warm)              | 100              |
| SLOAD (cold)               | 2,100            |
| SLOAD (warm)               | 100              |
| ERC20 transfer             | ~30,000-60,000   |
| NFT mint                   | ~50,000          |

______________________________________________________________________

## Profiling Tools

### Forge Debug

```bash
# Step through execution
forge test --match-test test_Withdraw -vvvv --debug
```

### Forge Trace

```bash
# Full execution trace with gas
forge test --match-test test_Withdraw -vvvvv
```

### External Tools

| Tool                                | Use Case                         |
| ----------------------------------- | -------------------------------- |
| [evm.codes](https://www.evm.codes/) | Opcode costs reference           |
| Tenderly                            | Production transaction profiling |
| Blocksec Phalcon                    | Visual transaction analysis      |

______________________________________________________________________

## Gas Snapshot Best Practices

1. **Commit `.gas-snapshot`** to track history
2. **Run on optimized profile** for production-accurate numbers
3. **Use concrete tests** for stable benchmarks (fuzz has variance)
4. **Separate gas tests** from functional tests
5. **Document thresholds** in comments or constants

______________________________________________________________________

## Commands Reference

```bash
# Snapshot operations
forge snapshot                        # Create/update snapshot
forge snapshot --diff .gas-snapshot   # Compare to baseline
forge snapshot --check .gas-snapshot  # Fail if regression

# Gas reporting
forge test --gas-report               # Function-level report
forge test --gas-report --json        # JSON output for CI

# Profiling
forge test --match-test <name> -vvvv  # Detailed trace
forge debug --debug <test>            # Interactive debugger
```
