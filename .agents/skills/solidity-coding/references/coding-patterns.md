# Solidity Coding Patterns

Rules and conventions for writing Solidity contracts. Find examples in the actual codebase.

## NatSpec Documentation

Full NatSpec lives in interfaces; implementations use `@inheritdoc InterfaceName`. At contract level, write
`/// @notice See the documentation in {IContractName}.`

### Interface Function NatSpec Order

1. `@notice` - What the function does (user-facing)
2. `@dev` - Technical details, emitted events
3. `Notes:` - Important behavioral notes (bullet list)
4. `Requirements:` - Preconditions (bullet list)
5. `@param` - Each parameter
6. `@return` - Return value(s)

---

## CEI Pattern (Checks-Effects-Interactions)

### Order

1. **CHECKS** - Validate inputs and state, revert if invalid
2. **EFFECTS** - Update state before any external calls
3. **INTERACTIONS** - External calls last (token transfers, hooks)
4. **PROTOCOL INVARIANT** (optional) - `assert()` post-interaction state when a cheap protocol invariant exists

### When to Use CEI-PI

Use step 4 (CEI-PI / FREI-PI) only when a protocol-level invariant can be cheaply verified. Default to plain CEI
otherwise. See `SablierFlow._withdraw` for a production example.

---

## Memory vs Storage

- **`memory`** - Read-only access, copies data (cheaper for multiple reads)
- **`storage`** - Direct reference, writes persist (needed for modifications)

---

## Safe Token Transfers

Always use `SafeERC20` for token transfers:

```solidity
using SafeERC20 for IERC20;
token.safeTransfer(to, amount);
token.safeTransferFrom(from, to, amount);
```

---

## Low-Level Calls

Use low-level calls for external contracts that might not implement standard interfaces. Check `success` and
`returnData.length` before decoding.
