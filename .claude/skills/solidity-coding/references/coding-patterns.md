# Solidity Coding Patterns

Rules and conventions for writing Solidity contracts. Find examples in the actual codebase.

## NatSpec Documentation

### Rules

1. Full NatSpec lives in **interfaces only**
2. Implementations use `@inheritdoc InterfaceName`
3. Contract-level: `/// @notice See the documentation in {IContractName}.`

### Interface Function NatSpec Order

1. `@notice` - What the function does (user-facing)
2. `@dev` - Technical details, emitted events
3. `Notes:` - Important behavioral notes (bullet list)
4. `Requirements:` - Preconditions (bullet list)
5. `@param` - Each parameter
6. `@return` - Return value(s)

______________________________________________________________________

## Error Handling

### Naming Convention

`{ContractName}_{ErrorDescription}` - e.g., `TokenVault_Overdraw`

### Rules

1. **One specific error per failure mode** - Never use generic catch-all errors
2. **Separate validation checks** - Don't combine conditions that warrant different errors
3. Define errors in `libraries/Errors.sol` with section comments
4. Include debugging parameters in error signature
5. Add NatSpec: `/// @notice Thrown when...`

______________________________________________________________________

## Modifiers

### Order in Function Signature

1. Visibility (`external`, `public`, `internal`, `private`)
2. Mutability (`payable`, `view`, `pure`)
3. Override (`override`)
4. Custom modifiers (guard conditions first: `noDelegateCall`, `notNull`)

______________________________________________________________________

## Section Comments

Use the `headers` CLI tool to generate properly aligned section headers:

```bash
headers "USER-FACING READ-ONLY FUNCTIONS"
```

### Standard Sections (in order)

1. CONSTRUCTOR
2. USER-FACING READ-ONLY FUNCTIONS
3. USER-FACING STATE-CHANGING FUNCTIONS
4. INTERNAL READ-ONLY FUNCTIONS
5. INTERNAL STATE-CHANGING FUNCTIONS
6. PRIVATE READ-ONLY FUNCTIONS
7. PRIVATE STATE-CHANGING FUNCTIONS

______________________________________________________________________

## Imports

### Rules

1. **Named imports only** - Use curly braces: `import { IERC20 } from "..."`
2. **Alphabetical order** within each group
3. **Order**: External packages → Internal shared → Local

______________________________________________________________________

## Storage Packing

### Rules

1. Group smaller types together to fit in 32-byte slots
2. Add slot comments showing byte usage
3. Use `uint40` for timestamps (5 bytes), `uint128` for amounts (16 bytes)
4. Addresses are 20 bytes, bools are 1 byte

______________________________________________________________________

## CEI Pattern (Checks-Effects-Interactions)

### Order

1. **CHECKS** - Validate inputs and state, revert if invalid
2. **EFFECTS** - Update state before any external calls
3. **INTERACTIONS** - External calls last (token transfers, hooks)
4. **PROTOCOL INVARIANT** (optional) - `assert()` post-interaction state when a cheap protocol invariant exists

### When to Use CEI-PI

Use step 4 (CEI-PI / FREI-PI) only when a protocol-level invariant can be cheaply verified. Default to plain CEI
otherwise. See `SablierFlow._withdraw` for a production example.

______________________________________________________________________

## Memory vs Storage

- **`memory`** - Read-only access, copies data (cheaper for multiple reads)
- **`storage`** - Direct reference, writes persist (needed for modifications)

______________________________________________________________________

## Safe Token Transfers

Always use `SafeERC20` for token transfers:

```solidity
using SafeERC20 for IERC20;
token.safeTransfer(to, amount);
token.safeTransferFrom(from, to, amount);
```

______________________________________________________________________

## Low-Level Calls

Use low-level calls for external contracts that might not implement standard interfaces. Check `success` and
`returnData.length` before decoding.
