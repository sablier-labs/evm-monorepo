# Pre-Audit Checklist

Prepare code for external security audit. Complete this checklist before sending to auditors.

## Documentation

### Code Documentation

- [ ] All public/external functions have NatSpec (`@notice`, `@dev`, `@param`, `@return`)
- [ ] Complex algorithms have inline comments explaining logic
- [ ] State variables have comments explaining purpose
- [ ] Magic numbers replaced with named constants
- [ ] Known limitations documented in code comments

### Protocol Documentation

- [ ] Architecture diagram provided
- [ ] State machine diagram for statuses/transitions
- [ ] Sequence diagrams for key flows (create, withdraw, cancel)
- [ ] Trust assumptions documented (who can do what)
- [ ] External dependencies listed with versions

### Invariants Document

- [ ] All invariants enumerated in `tests/invariant/README.md`
- [ ] Invariants categorized by severity
- [ ] Each invariant has corresponding test

---

## Code Quality

### Compilation

- [ ] Compiles with no warnings (even at highest level)
- [ ] Compiles with latest stable Solidity version
- [ ] No unused imports
- [ ] No unused variables or functions
- [ ] No commented-out code

### Style & Conventions

- [ ] Consistent naming conventions throughout
- [ ] Import ordering: external → internal → local
- [ ] Function ordering: visibility → mutability → override → custom
- [ ] Contracts inherited in alphabetical order
- [ ] Section comments for code organization

### Gas Optimization

- [ ] Gas snapshot captured and committed
- [ ] No obvious gas inefficiencies (unbounded loops, redundant storage reads)
- [ ] Storage packing reviewed

---

## Security Hardening

### Access Control

| Check                                     | Status |
| ----------------------------------------- | ------ |
| All admin functions have access modifiers | [ ]    |
| Ownership transfer is two-step            | [ ]    |
| No functions missing access control       | [ ]    |
| Admin capabilities documented             | [ ]    |

### Reentrancy Protection

| Check                                                | Status |
| ---------------------------------------------------- | ------ |
| CEI pattern followed in all state-changing functions | [ ]    |
| External calls identified and reviewed               | [ ]    |
| Callbacks (hooks) called after state updates         | [ ]    |

### Input Validation

| Check                              | Status |
| ---------------------------------- | ------ |
| All user inputs validated          | [ ]    |
| Zero address checks where relevant | [ ]    |
| Bounds checking on amounts/arrays  | [ ]    |
| Array length limits enforced       | [ ]    |

### Token Handling

| Check                                                   | Status |
| ------------------------------------------------------- | ------ |
| SafeERC20 used for all transfers                        | [ ]    |
| Fee-on-transfer tokens handled (or explicitly excluded) | [ ]    |
| Rebasing tokens handled (or explicitly excluded)        | [ ]    |
| Token decimals handled correctly                        | [ ]    |

---

## Testing

### Coverage

- [ ] Line coverage > 90%
- [ ] Branch coverage > 85%
- [ ] All error paths tested
- [ ] All modifiers tested

### Test Types

| Test Type                   | Coverage                              |
| --------------------------- | ------------------------------------- |
| Unit/Integration (concrete) | [ ] All public functions              |
| Fuzz tests                  | [ ] All functions with numeric inputs |
| Invariant tests             | [ ] All protocol invariants           |
| Fork tests                  | [ ] Token integrations                |

### Edge Cases

- [ ] Zero amounts tested
- [ ] Empty arrays tested
- [ ] Max values tested (type(uint256).max, etc.)
- [ ] Boundary conditions tested
- [ ] Time-based edge cases (block.timestamp)

---

## Static Analysis

### Slither

```bash
slither src/ --exclude-dependencies --exclude-informational
```

- [ ] All findings reviewed
- [ ] False positives documented
- [ ] Legitimate findings fixed

### Aderyn

```bash
aderyn src/
```

- [ ] All findings reviewed
- [ ] False positives documented

### Custom Detectors (if any)

- [ ] Protocol-specific detectors run
- [ ] Findings addressed

---

## Dependency Review

### External Dependencies

| Dependency   | Version | Audited | Notes    |
| ------------ | ------- | ------- | -------- |
| OpenZeppelin | x.x.x   | Yes     |          |
| Solady       | x.x.x   | Yes     |          |
| forge-std    | x.x.x   | N/A     | Dev only |

### Dependency Checklist

- [ ] All dependencies pinned to specific versions
- [ ] No known vulnerabilities in dependencies
- [ ] Upgrade paths documented if using upgradeable deps

---

## Deployment Readiness

### Constructor/Initialization

- [ ] Constructor parameters documented
- [ ] Initialization cannot be front-run
- [ ] Re-initialization prevented (if applicable)
- [ ] Default values are safe

### Upgradeability (if applicable)

- [ ] Storage gaps in all base contracts
- [ ] No storage variable reordering
- [ ] Initializers use `reinitializer(version)`
- [ ] Implementation has `_disableInitializers()`

---

## Scope Definition

### In Scope

List all contracts to be audited:

```
src/
├── MainContract.sol          ✓ In scope
├── abstracts/
│   ├── Feature1.sol          ✓ In scope
│   └── Feature2.sol          ✓ In scope
├── interfaces/               ✗ Out of scope (no logic)
├── libraries/
│   ├── Errors.sol            ✗ Out of scope (no logic)
│   └── Helpers.sol           ✓ In scope
└── types/                    ✗ Out of scope (no logic)
```

### Out of Scope

- [ ] Test files
- [ ] Mock contracts
- [ ] Deployment scripts
- [ ] External dependencies

### Lines of Code

```bash
# Count in-scope lines
cloc --include-lang=Solidity --exclude-dir=test,mocks,interfaces,types src/
```

---

## Audit Package

### Files to Provide

1. **Source code** - Clean repository or archive
2. **Documentation** - Architecture, state machines, invariants
3. **Test suite** - Full test suite with instructions
4. **Deployment info** - Target chains, expected parameters
5. **Previous audits** - Reports from prior versions
6. **Known issues** - List of accepted risks

### Build Instructions

````markdown
## Building

Requirements: Foundry (forge, cast, anvil)

```bash
git clone <repo>
cd <repo>
just setup
just build-all
just test-all
```
````

```

---

## Final Verification

Before sending to auditors:

- [ ] Fresh clone builds and tests pass
- [ ] All checklist items addressed
- [ ] Scope document prepared
- [ ] Contact person identified for auditor questions
- [ ] Timeline and deliverables agreed
```
