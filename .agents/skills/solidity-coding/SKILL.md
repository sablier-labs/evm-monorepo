---
name: solidity-coding
description:
  Write production-quality Solidity contracts. Trigger phrases - write contract, implement function, add feature, add
  error, gas optimization, event design, contract architecture, or when working in src/ directories.
---

# Solidity Contract Development Skill

This skill provides expertise for writing production-quality Solidity contracts following industry best practices.

## Bundled References

For detailed patterns and code examples, read these reference files:

| Reference                            | Content                                                      | When to Read                         |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------ |
| `references/coding-patterns.md`      | NatSpec, CEI, memory vs storage, token transfers, low-level  | Before writing any contract code     |
| `references/security-practices.md`   | Access control, hooks, arithmetic, EIP-7702, upgrades        | When implementing state changes      |
| `references/gas-optimization.md`     | EIP-1153, L2 patterns, Solady, storage packing and caching   | When optimizing contract efficiency  |
| `references/event-design.md`         | Event design for The Graph and indexers                      | When adding events to contracts      |
| `references/versioning-migration.md` | Interface versioning, storage migration, deprecation         | When releasing new contract versions |
| `references/sablier-conventions.md`  | Sablier abstracts, interfaces, access control, utils package | When working in Sablier repos        |
| `references/nft-descriptor.md`       | Onchain NFT metadata and SVG generation                      | When implementing tokenURI           |

## Conventions

### Naming

| Element            | Convention                 | Example                      |
| ------------------ | -------------------------- | ---------------------------- |
| Contract / Library | PascalCase                 | `SablierLockup`              |
| Interface          | I + PascalCase             | `ISablierLockup`             |
| Abstract           | `Sablier{Feature}`         | `SablierLockupDynamic`       |
| Library            | `{Domain}Math`, `Helpers`  | `LockupMath`, `Helpers`      |
| Types              | Namespace library          | `Lockup.Stream`, `Flow.Rate` |
| Function           | camelCase                  | `withdrawableAmountOf`       |
| Variable           | camelCase                  | `streamId`                   |
| Constant           | SCREAMING_SNAKE            | `MAX_SEGMENT_COUNT`          |
| Private/Internal   | \_underscore prefix        | `_streams`                   |
| Error              | `{Contract}_{Description}` | `SablierLockup_Overdraw`     |

### Imports

1. Named imports only: `import { IERC20 } from "..."`.
2. Two groups separated by a blank line: package imports (including `@sablier/*`), then relative local imports.
3. Sort each group alphabetically by import path.

### Directory Layout

```
src/
├── MainContract.sol     # Entry point
├── abstracts/           # Inheritance chain (state, features, base contracts)
├── interfaces/          # Public APIs - NatSpec lives here (use @inheritdoc in impl)
├── libraries/           # Errors.sol, Helpers.sol, Math libraries
└── types/               # Structs, enums, namespace libraries
```

### Inheritance

Inherit in **alphabetical order**:

```solidity
contract SablierLockup is
    Batch,
    Comptrollerable,
    ERC721,
    ISablierLockup,
    SablierLockupDynamic,
    SablierLockupLinear,
    SablierLockupPriceGated,
    SablierLockupTranched
{ ... }
```

### Sections and Function Ordering

Group functions under section headers in this order, omitting empty sections. Generate aligned headers with the
`headers` CLI, e.g. `headers "USER-FACING READ-ONLY FUNCTIONS"`.

1. CONSTRUCTOR
2. MODIFIERS
3. USER-FACING READ-ONLY FUNCTIONS
4. USER-FACING STATE-CHANGING FUNCTIONS
5. INTERNAL READ-ONLY FUNCTIONS
6. INTERNAL STATE-CHANGING FUNCTIONS
7. PRIVATE READ-ONLY FUNCTIONS
8. PRIVATE STATE-CHANGING FUNCTIONS

In a signature, order modifiers as visibility → mutability → `override` → custom modifiers, with guards such as
`noDelegateCall` and `notNull` first.

## Contract Checklist

When writing a new contract or function:

- [ ] Correct license and pragma
- [ ] Imports, inheritance, and sections ordered as above
- [ ] Full NatSpec in the interface; `@inheritdoc` in the implementation (see `references/coding-patterns.md`)
- [ ] One specific error per failure mode (see [Errors](#errors))
- [ ] Checks-effects-interactions ordering
- [ ] `SafeERC20` for token transfers
- [ ] `uint40` for timestamps, `uint128` for amounts
- [ ] Storage packing considered for new structs (see `references/gas-optimization.md`)
- [ ] Contract size under the 24kb limit

## Common Tasks

### Add a Function

1. Add the signature and full NatSpec to the interface. State-changing functions also document Notes and Requirements.
2. Implement it with `@inheritdoc InterfaceName` in the matching section.
3. Add guard modifiers: `noDelegateCall` for state-changing functions, `notNull(id)` when reading resource state.
4. Follow CEI and emit events after state changes.

### Errors

1. Define errors in the package's `libraries/Errors.sol`, grouped under one section comment per contract.
2. Name them `{ContractName}_{ErrorDescription}` and document them with `/// @notice Thrown when...`.
3. Use one specific error per failure mode; never combine conditions that warrant different errors into one check.
4. Include parameters that help debugging, e.g. both the requested and the available value.
5. Revert with `revert Errors.ContractName_ErrorDescription(...)`.

```solidity
/// @notice Thrown when trying to withdraw more than available.
error SablierLockup_Overdraw(uint256 streamId, uint128 amount, uint128 withdrawableAmount);
```

### Add a Struct

1. Define it in the `types/` directory.
2. Pack fields for gas efficiency.
3. Document the struct with NatSpec, using `@param` for each field.

## Contract Size Limit

Contracts must stay under the **24kb bytecode limit**. Check with the optimized profile:

```bash
just <pkg>::build-optimized --sizes
```

If a contract exceeds the limit:

1. **Extract logic into external libraries** - Use `public`/`external` library functions instead of `internal`
2. Split into multiple contracts via inheritance
3. Remove unused functions
4. Use custom errors instead of revert strings

### External Libraries Pattern

`internal` library functions are inlined into the contract bytecode. `public`/`external` library functions are called
via `DELEGATECALL`, keeping bytecode smaller but costing slightly more gas per call:

```solidity
library LockupMath {
    function calculateStreamedAmountLL(...) external view returns (uint128) { ... }
}

contract SablierLockup {
    function _streamedAmountOf(uint256 streamId) internal view override returns (uint128 streamedAmount) {
        // ...
        streamedAmount = LockupMath.calculateStreamedAmountLL({ ... });
    }
}
```

## Stack Too Deep

Bundle local variables into an in-memory `{FunctionName}Vars` struct:

```solidity
/// @dev Needed to avoid Stack Too Deep.
struct TokenURIVars {
    address token;
    uint128 depositedAmount;
    ISablierLockup lockup;
    // ...
}

function tokenURI(IERC721Metadata lockup, uint256 streamId) external view override returns (string memory uri) {
    TokenURIVars memory vars;

    vars.lockup = ISablierLockup(address(lockup));
    vars.depositedAmount = vars.lockup.getDepositedAmount(streamId);
    // ... use vars.field instead of separate local variables
}
```

Place `*Vars` structs in `types/DataTypes.sol` if reused, or inline in the contract if function-specific.

## Completion

Finish only after `just <pkg>::build` succeeds for every touched package and the new code satisfies the contract
checklist above. Report the build result and any checklist item left open.
