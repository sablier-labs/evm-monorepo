---
name: solidity-coding
user-invocable: true
description: Write production-quality Solidity contracts. Trigger phrases - write contract, implement function, add feature, add error, gas optimization, event design, contract architecture, or when working in src/ directories.
---

# Solidity Contract Development Skill

This skill provides expertise for writing production-quality Solidity contracts following industry best practices.

## Bundled References

For detailed patterns and code examples, read these reference files:

| Reference                                                           | Content                                              | When to Read                         |
| ------------------------------------------------------------------- | ---------------------------------------------------- | ------------------------------------ |
| `.claude/skills/solidity-coding/references/coding-patterns.md`      | NatSpec, errors, modifiers, imports, section headers | Before writing any contract code     |
| `.claude/skills/solidity-coding/references/security-practices.md`   | CEI, access control, EIP-7702, upgrades              | When implementing state changes      |
| `.claude/skills/solidity-coding/references/gas-optimization.md`     | EIP-1153, L2 patterns, Solady, storage caching       | When optimizing contract efficiency  |
| `.claude/skills/solidity-coding/references/event-design.md`         | Event design for The Graph and indexers              | When adding events to contracts      |
| `.claude/skills/solidity-coding/references/versioning-migration.md` | Interface versioning, storage migration, deprecation | When releasing new contract versions |
| `.claude/skills/solidity-coding/references/sablier-conventions.md`  | Sablier-specific naming, patterns, and examples      | When working in Sablier repos        |
| `.claude/skills/solidity-coding/references/nft-descriptor.md`       | Onchain NFT metadata and SVG generation              | When implementing tokenURI           |

> **Note**: Your repo's agent will provide repo-specific structure (package locations, inheritance hierarchies, etc.)

## Quick Conventions Reference

### Naming

| Element            | Convention                 | Example                |
| ------------------ | -------------------------- | ---------------------- |
| Contract / Library | PascalCase                 | `TokenVault`           |
| Interface          | I + PascalCase             | `ITokenVault`          |
| Function           | camelCase                  | `withdrawableAmountOf` |
| Variable           | camelCase                  | `streamId`             |
| Constant           | SCREAMING_SNAKE            | `MAX_SEGMENT_COUNT`    |
| Private/Internal   | \_underscore prefix        | `_balances`            |
| Error              | `{Contract}_{Description}` | `TokenVault_Overdraw`  |

### Import Ordering

1. Alphabetical order
2. External imports first, local imports second

### Function Ordering

1. Constructor
2. Receive/Fallback (if any)
3. External functions (view/pure first, then state-changing)
4. Public functions (view/pure first, then state-changing)
5. Internal functions
6. Private functions

### Key Principles

1. **NatSpec**: Use `@inheritdoc` in implementations; full docs live in interfaces
2. **Errors**: One specific error per failure mode; never use generic catch-all errors
3. **CEI Pattern**: Always checks → effects → interactions
4. **SafeERC20**: Always use `safeTransfer` and `safeTransferFrom`
5. **Timestamps**: Use `uint40` for all timestamps
6. **Amounts**: Use `uint128` for token amounts

## Contract Structure Pattern

### Standard Directory Layout

```
src/
├── MainContract.sol     # Entry point
├── abstracts/           # Inheritance chain (state, features, base contracts)
├── interfaces/          # Public APIs - NatSpec lives here (use @inheritdoc in impl)
├── libraries/           # Errors.sol, Helpers.sol, Math libraries
└── types/               # Structs, enums, namespace libraries
```

### Inheritance Pattern

Inherit in **alphabetical order**:

```solidity
contract TokenVault is Batch, ERC721, ITokenVault, VaultDynamic, VaultLinear { ... }
```

## Writing New Contract Code

### Contract Checklist

When writing a new contract or function:

- [ ] Correct license and pragma
- [ ] Imports ordered: external → internal → local
- [ ] Named imports only (use curly braces)
- [ ] Section comments for code organization
- [ ] `@inheritdoc` for interface implementations
- [ ] Specific errors for each failure mode
- [ ] Checks-effects-interactions ordering
- [ ] SafeERC20 for token transfers
- [ ] `uint40` for timestamps, `uint128` for amounts
- [ ] Storage packing considered for new structs
- [ ] Contract size under 24kb limit

### Contract Size Limit

Contracts must stay under the **24kb bytecode limit**. Verify with the optimized profile:

```bash
forge build --sizes
```

If a contract exceeds the limit:

1. **Extract logic into external libraries** - Use `public`/`external` library functions instead of `internal`
2. Split into multiple contracts via inheritance
3. Remove unused functions
4. Use shorter error messages or custom errors

#### External Libraries Pattern

Use `public` library functions to reduce contract size (called via `DELEGATECALL` rather than inlined):

```solidity
// Library with PUBLIC functions (not inlined, reduces contract size)
library VaultMath {
    function calculateAmount(...) public pure returns (uint128) { ... }
}

library Helpers {
    function validateParams(...) public view { ... }
}

// Main contract calls library functions (DELEGATECALL, not inlined)
contract TokenVault {
    function _computeAmount(uint256 id) private view returns (uint128) {
        return VaultMath.calculateAmount(...);
    }
}
```

**Key insight**: `internal` library functions are inlined into the contract bytecode. `public`/`external` library
functions are called via `DELEGATECALL`, keeping bytecode smaller but costing slightly more gas per call.

### Stack Too Deep

When you encounter "Stack Too Deep" errors, use an in-memory struct to bundle local variables:

```solidity
/// @dev Needed to avoid Stack Too Deep.
struct ComputeVars {
    address token;
    string tokenSymbol;
    uint128 depositedAmount;
    string json;
    ITokenVault vault;
    string status;
}

function compute(uint256 id) external view returns (string memory result) {
    ComputeVars memory vars;

    vars.vault = ITokenVault(address(this));
    vars.depositedAmount = vars.vault.getDepositedAmount(id);
    vars.token = address(vars.vault.getToken(id));
    // ... use vars.field instead of separate local variables
}
```

Place `*Vars` structs in `types/DataTypes.sol` if reused, or inline in the contract if function-specific.

### Adding Errors

1. Add error to package's `libraries/Errors.sol`
2. Use naming: `{ContractName}_{ErrorDescription}`
3. Add NatSpec: `/// @notice Thrown when...`
4. Include relevant parameters for debugging

```solidity
/// @notice Thrown when trying to withdraw more than available.
error TokenVault_Overdraw(uint256 id, uint128 amount, uint128 withdrawableAmount);
```

### Adding Functions

1. Add signature and full NatSpec to interface
2. Implement in contract with `@inheritdoc`
3. Place in correct section (external/public/internal/private)
4. Order modifiers: visibility → mutability → override → custom

## Common Patterns

### Safe Token Transfers

```solidity
using SafeERC20 for IERC20;

// Safe transfers handle non-standard ERC20s
token.safeTransfer(to, amount);
token.safeTransferFrom(from, to, amount);
```

## Common Tasks

### Add a view function

1. Add to interface with full NatSpec (notice, dev, param, return)
2. Implement with `@inheritdoc InterfaceName`
3. Add appropriate modifiers (e.g., `notNull(id)` if accessing resource state)

### Add a state-changing function

1. Add to interface with NatSpec (include Notes and Requirements sections)
2. Implement with `@inheritdoc`
3. Add modifiers: `noDelegateCall`, `notNull(id)`, etc.
4. Follow CEI pattern
5. Emit events after state changes

### Add a new error

1. Define in `libraries/Errors.sol` with section comment
2. Add NatSpec: `/// @notice Thrown when...`
3. Include debugging parameters
4. Use in contract: `revert Errors.ContractName_ErrorDesc(...)`

### Add a new struct

1. Define in `types/` directory
2. Pack fields for gas efficiency (see `.claude/skills/solidity-coding/references/coding-patterns.md`)
3. Add NatSpec for struct and each field
4. Use `@param` for each field in struct NatSpec

______________________________________________________________________

## Example Invocations

Test this skill with these prompts:

1. **New function**: "Add a `getStreamBalance` view function to the ISablierFlow interface"
2. **Error handling**: "Add a `Flow_InsufficientBalance` error with debugging parameters"
3. **Gas optimization**: "Optimize the `_withdraw` function using storage caching"
4. **Contract structure**: "Create the interface for a new `TokenVesting` contract with deposit, withdraw, and claim
   functions"
