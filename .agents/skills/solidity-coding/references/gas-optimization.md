# Gas Optimization

Gas optimization rules. Find examples in the actual codebase.

## Modern EVM Features (Solidity 0.8.24+)

### Transient Storage (EIP-1153)

Use `tstore`/`tload` for data needed only within a transaction (cheaper than storage):

```solidity
// Reentrancy lock with transient storage (Cancun+)
bytes32 constant LOCK_SLOT = keccak256("REENTRANCY_LOCK");

modifier nonReentrantTransient() {
    assembly {
        if tload(LOCK_SLOT) { revert(0, 0) }
        tstore(LOCK_SLOT, 1)
    }
    _;
    assembly {
        tstore(LOCK_SLOT, 0)
    }
}
```

**Callback Data Pattern** - Pass data to hooks without storage:

```solidity
// Store callback context before external call
bytes32 constant CALLBACK_CONTEXT_SLOT = keccak256("CALLBACK_CONTEXT");

function executeWithCallback(uint256 streamId, bytes calldata data) external {
    assembly {
        // Pack streamId and caller into one slot
        let packed := or(shl(96, caller()), streamId)
        tstore(CALLBACK_CONTEXT_SLOT, packed)
    }

    // External call that triggers callback
    IRecipient(recipient).onStreamAction(streamId, data);

    assembly {
        tstore(CALLBACK_CONTEXT_SLOT, 0) // Clear after use
    }
}

function _getCallbackContext() internal view returns (address caller_, uint256 streamId) {
    assembly {
        let packed := tload(CALLBACK_CONTEXT_SLOT)
        caller_ := shr(96, packed)
        streamId := and(packed, 0xFFFFFFFFFFFFFFFFFFFFFFFF)
    }
}
```

**Flash Loan State Pattern**:

```solidity
bytes32 constant FLASH_LOAN_SLOT = keccak256("FLASH_LOAN_ACTIVE");

function flashLoan(uint256 amount) external {
    assembly { tstore(FLASH_LOAN_SLOT, amount) }

    token.transfer(msg.sender, amount);
    IFlashBorrower(msg.sender).onFlashLoan(amount);

    // Verify repayment
    assembly {
        if tload(FLASH_LOAN_SLOT) { revert(0, 0) } // Not repaid
    }
}

function repayFlashLoan(uint256 amount) external {
    token.transferFrom(msg.sender, address(this), amount);
    assembly { tstore(FLASH_LOAN_SLOT, 0) } // Mark as repaid
}
```

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

______________________________________________________________________

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

______________________________________________________________________

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

______________________________________________________________________

## Storage

| Technique            | Rule                                                                       |
| -------------------- | -------------------------------------------------------------------------- |
| Cache reads          | Read storage into memory once, not multiple times                          |
| Storage pointers     | Use direct `_entries[id].field = value` for single-field writes            |
| Avoid zero→non-zero  | Design state to minimize zero-to-nonzero transitions (22,100 vs 5,000 gas) |
| Mappings over arrays | Mappings skip bounds checks (~2,100 gas savings per read)                  |
| Constants/Immutables | Use for values known at compile/deploy time (no storage read)              |

______________________________________________________________________

## Type Sizes

| Type      | Use Case                            | Size     |
| --------- | ----------------------------------- | -------- |
| `uint256` | Standalone variables, loop counters | 32 bytes |
| `uint128` | Token amounts (packs 2 per slot)    | 16 bytes |
| `uint40`  | Timestamps                          | 5 bytes  |
| `bool`    | Flags (pack multiple per slot)      | 1 byte   |

**Warning**: Smaller types for standalone variables waste gas on casting. Use `uint256` unless packing.

______________________________________________________________________

## Bitmaps

**Rule**: Use bitmaps for tracking many booleans (256 per storage slot vs 1 per slot).

______________________________________________________________________

## Functions

| Technique        | Rule                                                     |
| ---------------- | -------------------------------------------------------- |
| Calldata         | Use `calldata` for read-only array/struct parameters     |
| Custom errors    | Use over require strings (4 bytes vs 64+ bytes)          |
| Payable          | Add to admin functions to skip msg.value check (~20 gas) |
| Modifier helpers | Call private functions from modifiers (reduces bytecode) |

______________________________________________________________________

## Loops

### Gas-Optimal Pattern

```solidity
uint256 count = array.length;
for (uint256 i; i < count; ) {
    // ...
    unchecked { ++i; }
}
```

**Rules**:

- Cache array length outside loop
- Use pre-increment (`++i`)
- Use unchecked for iterator
- Initialize `i` without `= 0`

______________________________________________________________________

## Short-Circuit Evaluation

- **AND (&&)**: Put cheap/likely-false conditions first
- **OR (||)**: Put cheap/likely-true conditions first

______________________________________________________________________

## External Calls

**Rule**: Cache results of repeated external calls.

______________________________________________________________________

## Compiler Settings

| Optimizer Runs | Optimizes For                              |
| -------------- | ------------------------------------------ |
| Low (200)      | Deployment cost                            |
| High (10,000+) | Runtime cost (frequently-called contracts) |

______________________________________________________________________

## Anti-Patterns

1. **Don't optimize prematurely** - Readability over marginal gains
2. **Don't use small types standalone** - Casting overhead negates savings
3. **Don't over-optimize view functions** - External view calls are free
