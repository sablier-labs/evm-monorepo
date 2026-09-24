# Security Practices

Security rules for Solidity contracts. Find examples in the actual codebase.

> **Note**: CEI pattern, CEI-PI (FREI-PI), and SafeERC20 basics are covered in `coding-patterns.md`. This reference
> covers advanced patterns.

## Access Control

Use two-step ownership transfer for critical roles. See `sablier-conventions.md` for the shared access-control bases.

---

## Prevent Delegate Calls

**Rule**: Inherit `NoDelegateCall` and apply `noDelegateCall` modifier to sensitive functions.

**Why**: Prevents malicious contracts from executing your logic in their context.

---

## Safe Arithmetic

### Unchecked Blocks

**Rule**: Only use `unchecked` when overflow is mathematically impossible.

Safe cases:

- Incrementing IDs (always start from 0, bounded by practical limits)
- Subtracting amounts that were previously added (aggregate tracking)
- Differences where minuend >= subtrahend is guaranteed

### Defensive Comparisons

**Rule**: Use `>=` instead of `==` for depletion/completion checks (guards against unforeseen state).

---

## Input Validation

### Rules

1. Use modifiers for common patterns (`notNull`, `notZero`)
2. Validate addresses are not zero when relevant
3. Validate amounts are within acceptable bounds

---

## Hook Security

### Rules

1. External hooks must be explicitly allowlisted by the admin, e.g. `mapping(address => bool) _allowedToHook`
2. Validate that the hook returns the expected selector, reverting with a specific error otherwise
3. Hooks are called AFTER state changes (CEI pattern)

---

## Interface Validation

**Rule**: When accepting external contract addresses, validate they implement required interfaces via
`supportsInterface`.

---

## State Transitions

### Rules

1. Mark irreversible state changes explicitly (e.g., `isCancelable = false`)
2. Update related state variables atomically
3. Document invariants that must hold across transitions

---

## Account Abstraction Considerations (EIP-7702)

### EOA Code Execution

With EIP-7702 (Pectra), EOAs can delegate to contract code. Security implications:

| Risk                             | Mitigation                                         |
| -------------------------------- | -------------------------------------------------- |
| EOA becomes a contract mid-tx    | Don't assume `tx.origin == msg.sender` means EOA   |
| Code can be changed per-tx       | Cache critical checks, don't rely on `extcodesize` |
| Delegated EOAs can have fallback | Handle potential callback behavior                 |

### Safe Patterns

```solidity
// Instead of checking if caller is EOA
// BAD: if (msg.sender == tx.origin) { ... }

// GOOD: Check actual intent via signature or access control
// The caller being an EOA is not a security guarantee post-7702
```

### ERC-4337 Compatibility

If supporting smart contract wallets:

| Pattern               | Requirement                            |
| --------------------- | -------------------------------------- |
| Signature validation  | Support ERC-1271 `isValidSignature`    |
| Gas estimation        | Account for validation gas overhead    |
| Bundler compatibility | Don't rely on `tx.origin` for anything |

---

## Upgradeable Contract Security

### ERC-1967 Proxy Patterns

| Check                      | Verification                            |
| -------------------------- | --------------------------------------- |
| Storage slot collision     | Use ERC-1967 standard slots             |
| Implementation initialized | `_disableInitializers()` in constructor |
| No `selfdestruct`          | Never in implementation contracts       |

### UUPS vs Transparent

| Pattern     | Use When                                             |
| ----------- | ---------------------------------------------------- |
| UUPS        | Gas-efficient, upgrade logic in implementation       |
| Transparent | Clearer separation, admin cannot call implementation |

For storage layout rules and gaps, see `versioning-migration.md`.
