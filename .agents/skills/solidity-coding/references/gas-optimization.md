# Gas Optimization

Gas optimization rules. Find examples in the actual codebase.

## Modern EVM Features (Solidity 0.8.24+)

### Transient Storage (EIP-1153)

Use transient storage for data needed only within a transaction (`TSTORE`/`TLOAD` cost 100 gas each). It requires
`evm_version = "cancun"` or later. Prefer, in order:

1. OpenZeppelin `ReentrancyGuardTransient` for reentrancy locks.
2. `transient` state variables of value types (solc 0.8.28+):

   ```solidity
   bool private transient _locked;
   ```

3. OpenZeppelin `TransientSlot` or inline assembly for custom layouts (callback context, flash-loan accounting). Inline
   assembly accepts only literal number constants, so a `keccak256(...)` constant cannot appear in `tstore`/`tload`;
   hardcode the precomputed slot or use `TransientSlot`.

Clear transient values explicitly when a contract may be called several times in one transaction (multicall, batch).

| Use Case              | Gas Savings                      |
| --------------------- | -------------------------------- |
| Reentrancy guards     | ~2,900 gas (vs cold SSTORE)      |
| Callback data passing | ~20,000+ gas for complex data    |
| Flash loan state      | Significant for multi-step ops   |
| Cross-function flags  | Avoid storage for tx-scoped data |

**When to use transient storage**:

- Reentrancy locks
- Callback context (caller, amounts, IDs)
- Flash loan tracking
- Multi-step operation state
- Any data that resets after transaction

### PUSH0 Opcode (EIP-3855)

Automatically used by Solidity 0.8.20+ when targeting Shanghai+. Saves 2 gas per zero push.

**Compiler setting**: `evmVersion = "cancun"` in foundry.toml

### Via-IR Pipeline

Enable for complex contracts to allow cross-function optimizations:

```toml
[profile.optimized]
via_ir = true
optimizer_runs = 200
```

---

## L2-Specific Optimizations

### Calldata vs Computation Trade-off

| Chain             | Optimize For | Reason                         |
| ----------------- | ------------ | ------------------------------ |
| L1 Mainnet        | Computation  | Execution gas expensive        |
| Arbitrum/Optimism | Calldata     | L1 data posting dominates cost |
| Base              | Calldata     | Same as above                  |

### L2 Patterns

```solidity
// L1: Compute in contract (cheaper execution)
function getAmountL1(uint256[] calldata values) external pure returns (uint256 sum) {
    for (uint256 i; i < values.length; ++i) sum += values[i];
}

// L2: Pre-compute off-chain, pass result (smaller calldata)
function setAmountL2(uint256 precomputedSum) external {
    // Verify via merkle proof if needed
}
```

### L2-Specific Gas Estimation

```solidity
// Arbitrum: Use ArbGasInfo precompile
IArbGasInfo(0x000000000000000000000000000000000000006C).getCurrentTxL1GasFees();

// Optimism: Use L1Block contract for L1 gas price
IL1Block(0x4200000000000000000000000000000000000015).l1BaseFee();
```

---

## Alternative Libraries

### Solady (Gas-Optimized)

Consider [Solady](https://github.com/Vectorized/solady) for gas-critical paths:

| Component           | Solady Advantage                  |
| ------------------- | --------------------------------- |
| `SafeTransferLib`   | ~50 gas cheaper than OZ SafeERC20 |
| `FixedPointMathLib` | Optimized fixed-point math        |
| `LibString`         | Efficient string operations       |
| `SSTORE2/SSTORE3`   | Cheaper large data storage        |

**When to use Solady**:

- Gas-critical hot paths
- When audit budget covers additional dependency

**When to use OpenZeppelin**:

- Standard flows where gas isn't critical
- Maximum auditability and familiarity

---

## Storage

| Technique            | Rule                                                                       |
| -------------------- | -------------------------------------------------------------------------- |
| Cache reads          | Read storage into memory once, not multiple times                          |
| Storage pointers     | Use direct `_entries[id].field = value` for single-field writes            |
| Avoid zero→non-zero  | Design state to minimize zero-to-nonzero transitions (22,100 vs 5,000 gas) |
| Mappings over arrays | Mappings skip the array length `SLOAD` used for bounds checks              |
| Constants/Immutables | Use for values known at compile/deploy time (no storage read)              |

---

## Type Sizes

| Type      | Use Case                            | Size     |
| --------- | ----------------------------------- | -------- |
| `uint256` | Standalone variables, loop counters | 32 bytes |
| `uint128` | Token amounts (packs 2 per slot)    | 16 bytes |
| `uint40`  | Timestamps                          | 5 bytes  |
| `bool`    | Flags (pack multiple per slot)      | 1 byte   |

**Warning**: Smaller types for standalone variables waste gas on casting. Use `uint256` unless packing.

**Packing**: Group smaller types so they share 32-byte slots (addresses are 20 bytes, bools 1 byte), and add slot
comments showing byte usage.

---

## Bitmaps

**Rule**: Use bitmaps for tracking many booleans (256 per storage slot vs 1 per slot).

---

## Functions

| Technique        | Rule                                                     |
| ---------------- | -------------------------------------------------------- |
| Calldata         | Use `calldata` for read-only array/struct parameters     |
| Custom errors    | Use over require strings (4 bytes vs 64+ bytes)          |
| Payable          | Add to admin functions to skip msg.value check (~20 gas) |
| Modifier helpers | Call private functions from modifiers (reduces bytecode) |

---

## Loops

### Gas-Optimal Pattern

```solidity
uint256 count = array.length;
for (uint256 i; i < count; ++i) {
    // ...
}
```

**Rules**:

- Cache a storage array's length outside the loop
- Use pre-increment (`++i`)
- Skip manual `unchecked { ++i; }`: since solc 0.8.22 the compiler makes this increment unchecked when the body does not
  modify `i`
- Initialize `i` without `= 0`

---

## Short-Circuit Evaluation

- **AND (&&)**: Put cheap/likely-false conditions first
- **OR (||)**: Put cheap/likely-true conditions first

---

## External Calls

**Rule**: Cache results of repeated external calls.

---

## Compiler Settings

| Optimizer Runs | Optimizes For                              |
| -------------- | ------------------------------------------ |
| Low (200)      | Deployment cost                            |
| High (10,000+) | Runtime cost (frequently-called contracts) |

---

## Anti-Patterns

1. **Don't optimize prematurely** - Readability over marginal gains
2. **Don't use small types standalone** - Casting overhead negates savings
3. **Don't over-optimize view functions** - External view calls are free
