# Formal Verification

Symbolic execution and formal verification tools for proving contract correctness.

## Tool Overview

| Tool        | Type                | Best For                       | Integration     |
| ----------- | ------------------- | ------------------------------ | --------------- |
| **Halmos**  | Symbolic execution  | Foundry-native, quick setup    | Direct Foundry  |
| **Certora** | Formal verification | Complex invariants, production | Separate prover |
| **HEVM**    | Symbolic execution  | Dapptools heritage             | Foundry compat  |

______________________________________________________________________

## Halmos (Recommended)

Halmos is a symbolic testing tool that integrates with Foundry tests.

### Installation

```bash
pip install halmos
```

### Writing Symbolic Tests

Prefix tests with `check_` instead of `test_`:

```solidity
// tests/symbolic/Symbolic.t.sol
import { Test } from "forge-std/Test.sol";
import { SymTest } from "halmos-cheatcodes/SymTest.sol";

contract SymbolicTest is Test, SymTest {
    TokenVault vault;

    function setUp() public {
        vault = new TokenVault();
    }

    /// @notice Verify withdrawal never exceeds balance
    function check_WithdrawNeverExceedsBalance(uint256 depositAmount, uint256 withdrawAmount) public {
        // Bound inputs to reasonable ranges
        vm.assume(depositAmount > 0 && depositAmount < type(uint128).max);
        vm.assume(withdrawAmount > 0);

        vault.deposit(depositAmount);

        if (withdrawAmount > depositAmount) {
            // Should revert
            vm.expectRevert();
        }
        vault.withdraw(withdrawAmount);

        // Post-condition: balance >= 0 (implicit, but state this)
        assert(vault.balance() >= 0);
    }

    /// @notice Prove value conservation: deposited = withdrawn + remaining
    function check_ValueConservation(uint256 deposit, uint256 withdraw) public {
        vm.assume(deposit > 0 && deposit < type(uint128).max);
        vm.assume(withdraw <= deposit);

        vault.deposit(deposit);
        vault.withdraw(withdraw);

        uint256 remaining = vault.balance();
        assert(deposit == withdraw + remaining);
    }
}
```

### Running Halmos

```bash
# Run all symbolic tests
halmos

# Run specific test with higher loop bound
halmos --function check_ValueConservation --loop 10

# With contract size limit
halmos --solver-timeout-assertion 60000

# Generate counterexample
halmos --function check_WithdrawNeverExceedsBalance -vvv
```

### Halmos Best Practices

1. **Bound symbolic inputs** - Unbounded can cause solver timeout
2. **Use `vm.assume()` sparingly** - Each assumption narrows search space
3. **Check one property per test** - Easier to debug failures
4. **Start with simple invariants** - Build up complexity

### Common Halmos Patterns

```solidity
/// @notice No overflow on deposit
function check_NoOverflowDeposit(uint128 amount1, uint128 amount2) public {
    vault.deposit(amount1);
    vault.deposit(amount2);
    // If this passes, no overflow occurred
    assert(vault.totalDeposited() == uint256(amount1) + uint256(amount2));
}

/// @notice Access control holds
function check_OnlyOwnerCanPause(address caller) public {
    vm.assume(caller != vault.owner());
    vm.prank(caller);
    vm.expectRevert();
    vault.pause();
}

/// @notice State machine transitions
function check_ValidStateTransition(uint8 action) public {
    action = uint8(bound(action, 0, 3)); // 4 possible actions

    VaultState before = vault.state();

    if (action == 0) vault.deposit(1e18);
    else if (action == 1) vault.withdraw(1e18);
    else if (action == 2) vault.pause();
    else vault.resume();

    VaultState after = vault.state();

    // Assert valid transition
    assert(isValidTransition(before, after));
}
```

______________________________________________________________________

## Certora (Production-Grade)

For critical contracts requiring formal proofs.

### Setup

1. Install Certora CLI: `pip install certora-cli`
2. Create `certora/` directory
3. Write specs in CVL (Certora Verification Language)

### Spec Structure

```cvl
// certora/specs/Vault.spec

methods {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balance() external returns (uint256) envfree;
    function totalDeposited() external returns (uint256) envfree;
}

// Ghost variable to track sum of all balances
ghost mathint sumBalances {
    init_state axiom sumBalances == 0;
}

// Hook: update ghost on balance change
hook Sstore balances[KEY address user] uint256 newValue (uint256 oldValue) {
    sumBalances = sumBalances + newValue - oldValue;
}

// Invariant: sum of balances equals total deposited
invariant totalMatchesSum()
    to_mathint(totalDeposited()) == sumBalances;

// Rule: withdraw decreases balance
rule withdrawDecreasesBalance(uint256 amount) {
    env e;

    uint256 balanceBefore = balance();

    withdraw(e, amount);

    uint256 balanceAfter = balance();

    assert balanceAfter == balanceBefore - amount;
}

// Rule: only owner can pause
rule onlyOwnerCanPause(method f) filtered { f -> f.selector == sig:pause().selector } {
    env e;

    require e.msg.sender != owner();

    pause@withrevert(e);

    assert lastReverted;
}
```

### Running Certora

```bash
# Run verification
certoraRun certora/conf/Vault.conf

# With specific rule
certoraRun certora/conf/Vault.conf --rule withdrawDecreasesBalance
```

### Certora Config File

```json
// certora/conf/Vault.conf
{
  "files": ["src/Vault.sol"],
  "verify": "Vault:certora/specs/Vault.spec",
  "wait_for_results": "all",
  "msg": "Vault verification",
  "optimistic_loop": true,
  "loop_iter": 3
}
```

______________________________________________________________________

## When to Use Each

| Scenario                     | Tool    | Reason                      |
| ---------------------------- | ------- | --------------------------- |
| Quick property check         | Halmos  | No setup, runs with Foundry |
| Pre-audit verification       | Halmos  | Fast iteration              |
| Production mainnet contracts | Certora | Strongest guarantees        |
| Complex multi-contract       | Certora | Better abstraction support  |
| CI integration               | Halmos  | Faster, simpler             |

______________________________________________________________________

## Integration with Sablier Workflow

Add to QA phase:

```bash
# After step 8 (static analysis), before step 9 (gas regression)
halmos --function "check_*" --loop 5

# For mainnet deployment (optional)
certoraRun certora/conf/Protocol.conf
```

### Recommended Invariants to Verify

| Protocol | Invariant                                           |
| -------- | --------------------------------------------------- |
| Lockup   | `deposited >= withdrawn + refunded`                 |
| Lockup   | `streamedAmount` never decreases                    |
| Flow     | `balance + totalWithdrawn == totalDeposited`        |
| Flow     | `ongoingDebt == 0` when paused                      |
| Airdrops | `claimed + unclaimed + clawedBack == campaignTotal` |

______________________________________________________________________

## Resources

- [Halmos Documentation](https://github.com/a16z/halmos)
- [Certora Documentation](https://docs.certora.com/)
- [Trail of Bits Symbolic Testing Guide](https://blog.trailofbits.com/category/symbolic-execution/)
