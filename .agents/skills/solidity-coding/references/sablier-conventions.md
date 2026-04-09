# Sablier-Specific Conventions

Sablier-specific naming and patterns. Find code examples in the actual codebase.

## Naming Examples

| Element   | Convention                 | Sablier Example              |
| --------- | -------------------------- | ---------------------------- |
| Contract  | PascalCase                 | `SablierLockup`              |
| Interface | I + PascalCase             | `ISablierLockup`             |
| Error     | `{Contract}_{Description}` | `SablierLockup_Overdraw`     |
| Abstract  | `Sablier{Feature}`         | `SablierLockupDynamic`       |
| Library   | `{Domain}Math`, `Helpers`  | `LockupMath`, `Helpers`      |
| Types     | Namespace library          | `Lockup.Stream`, `Flow.Rate` |

______________________________________________________________________

## Error Library Pattern

Errors defined in dedicated `Errors.sol` per package with section comments by contract.

**Rules:**

- One specific error per failure mode (not generic catch-alls)
- Include diagnostic parameters
- Separate validation checks for distinct error conditions

______________________________________________________________________

## Abstract Contract Types

| Type              | Purpose                        | Example                |
| ----------------- | ------------------------------ | ---------------------- |
| State contracts   | Storage variables and getters  | `SablierLockupState`   |
| Feature contracts | Model-specific implementations | `SablierLockupDynamic` |
| Base contracts    | Shared functionality           | `SablierMerkleBase`    |

______________________________________________________________________

## Interface Organization

| Interface                  | Contains                 |
| -------------------------- | ------------------------ |
| `I{Contract}State.sol`     | Getter functions         |
| `I{Contract}.sol`          | State-changing functions |
| `I{Contract}Recipient.sol` | Hook interface           |

______________________________________________________________________

## Inheritance Pattern

Inherit in alphabetical order:

```
Batch, Comptrollerable, ERC721, ISablierLockup, SablierLockupDynamic, SablierLockupLinear, SablierLockupTranched
```

______________________________________________________________________

## Library Patterns

| Pattern             | Purpose                                    |
| ------------------- | ------------------------------------------ |
| `public` functions  | Reduce contract size (not inlined)         |
| Namespace libraries | Group related types (`Lockup.Stream`)      |
| Helper libraries    | Validation and calculation (`Helpers.sol`) |

______________________________________________________________________

## Access Control Bases

| Contract          | Modifier          | Use Case                     |
| ----------------- | ----------------- | ---------------------------- |
| `Adminable`       | `onlyAdmin`       | Single admin with transfer   |
| `RoleAdminable`   | `onlyRole(role)`  | Role-based access control    |
| `Comptrollerable` | `onlyComptroller` | Protocol-level admin actions |

______________________________________________________________________

## Cross-Package Imports

| From Package | Import Pattern                                      |
| ------------ | --------------------------------------------------- |
| evm-utils    | `@sablier/evm-utils/src/{Contract}.sol`             |
| lockup       | `@sablier/lockup/src/interfaces/ISablierLockup.sol` |
| types        | `@sablier/lockup/src/types/DataTypes.sol`           |

______________________________________________________________________

## Shared Utils Package

The `@sablier/evm-utils` package contains cross-cutting infrastructure shared across Lockup, Flow, and Airdrops.

### What Lives in Utils

| Category           | Examples                                     | Purpose                           |
| ------------------ | -------------------------------------------- | --------------------------------- |
| **Infrastructure** | `Comptrollerable`, `Batch`, `NoDelegateCall` | Cross-cutting concerns            |
| **Interfaces**     | `IComptrollerable`, `IBatch`                 | Shared API contracts              |
| **Test utilities** | `BaseTest`, `BaseScript`, ERC20 mocks        | Common test setup                 |
| **Core shared**    | `SablierComptroller`                         | Single instance for all protocols |

### What Stays in Its Package

| Category                            | Reason                          |
| ----------------------------------- | ------------------------------- |
| Protocol logic (`SablierLockup`)    | Protocol-specific behavior      |
| Protocol types (`Lockup.Segment`)   | Domain-specific data structures |
| Protocol errors (`SablierLockup_*`) | Package-scoped errors           |

### When to Move Logic to Utils

Move code to utils only when ALL conditions are met:

1. **Needed by 2+ packages** - Not just potentially useful, but actually used
2. **Stateless or shared state** - Uses only comptroller/admin state, no protocol-specific storage
3. **Cross-cutting concern** - Admin patterns, batching, security, testing infrastructure

**Anti-pattern**: Moving code to utils "just in case" it might be reused later.

______________________________________________________________________

## Hook Security Rules

1. External hooks must be explicitly allowlisted by admin
2. Store allowlist in mapping: `mapping(address => bool) _allowedToHook`
3. Validate hook returns correct selector
4. Revert with specific error on invalid selector

______________________________________________________________________

## Stack Too Deep Pattern

Use `{FunctionName}Vars` struct for functions with many local variables.

______________________________________________________________________

## Modifier Pattern

| Modifier           | Implementation                          |
| ------------------ | --------------------------------------- |
| `notNull(id)`      | Revert if stream doesn't exist          |
| `noDelegateCall()` | Call private helper `_noDelegateCall()` |

______________________________________________________________________

## Commands

```bash
just build-optimized <package> --sizes  # Check contract size under 24kb
```
