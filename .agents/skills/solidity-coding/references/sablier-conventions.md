# Sablier-Specific Conventions

Sablier-specific architecture and patterns. Find code examples in the actual codebase.

## Abstract Contract Types

| Type              | Purpose                        | Example                |
| ----------------- | ------------------------------ | ---------------------- |
| State contracts   | Storage variables and getters  | `SablierLockupState`   |
| Feature contracts | Model-specific implementations | `SablierLockupDynamic` |
| Base contracts    | Shared functionality           | `SablierMerkleBase`    |

---

## Interface Organization

| Interface                  | Contains                 |
| -------------------------- | ------------------------ |
| `I{Contract}State.sol`     | Getter functions         |
| `I{Contract}.sol`          | State-changing functions |
| `I{Contract}Recipient.sol` | Hook interface           |

---

## Access Control Bases

| Contract          | Modifier          | Use Case                     |
| ----------------- | ----------------- | ---------------------------- |
| `Adminable`       | `onlyAdmin`       | Single admin with transfer   |
| `RoleAdminable`   | `onlyRole(role)`  | Role-based access control    |
| `Comptrollerable` | `onlyComptroller` | Protocol-level admin actions |

---

## Cross-Package Imports

| From Package | Import Pattern                                      |
| ------------ | --------------------------------------------------- |
| evm-utils    | `@sablier/evm-utils/src/{Contract}.sol`             |
| lockup       | `@sablier/lockup/src/interfaces/ISablierLockup.sol` |
| types        | `@sablier/lockup/src/types/DataTypes.sol`           |

---

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
