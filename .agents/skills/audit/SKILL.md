---
name: audit
agent: Plan
user-invocable: true
description: Security audit and code review for Solidity smart contracts. Trigger phrases - audit, check PR, security review, pre-audit preparation, vulnerability check, or when preparing code for external audit.
---

# Audit Skill

Audit and code review guidance for Solidity smart contracts. For detailed vulnerability patterns, see bundled references.

## Bundled References

| Reference                                                    | Content                     | When to Read                  |
| ------------------------------------------------------------ | --------------------------- | ----------------------------- |
| `.claude/skills/audit/references/vulnerability-checklist.md` | 17 vulnerability categories | During security reviews       |
| `.claude/skills/audit/references/audit-workflow.md`          | Step-by-step audit process  | When conducting formal audits |
| `.claude/skills/audit/references/pre-audit-checklist.md`     | Code quality + testing prep | Before external audit         |

**Workflow**: Use `pre-audit-checklist` to prepare → `vulnerability-checklist` to review → `audit-workflow` for formal
process.

## Review Types

| Type            | Purpose                      | Depth    | When to Use                      |
| --------------- | ---------------------------- | -------- | -------------------------------- |
| **Self-Review** | Pre-submission sanity check  | Quick    | Before creating a PR             |
| **PR Review**   | Verify changes meet standard | Moderate | When reviewing others' PRs       |
| **Deep Review** | Thorough security analysis   | Deep     | Before mainnet deployment        |
| **Audit**       | Comprehensive security audit | Thorough | Pre-launch or after major change |

______________________________________________________________________

## Self-Review Checklist

### Code Quality

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] No commented-out code or debug statements
- [ ] No hardcoded test values in production code

### Style & Conventions

- [ ] Follows naming conventions
- [ ] Imports ordered: external → internal → local
- [ ] Functions ordered: external → public → internal → private
- [ ] NatSpec complete for public/external functions

### Logic

- [ ] Edge cases handled (zero amounts, empty arrays)
- [ ] Error messages are descriptive
- [ ] Events emitted for all state changes
- [ ] Access control is appropriate

### Security

- [ ] CEI pattern followed (no state changes after external calls)
- [ ] SafeERC20 used for token transfers
- [ ] No unchecked arithmetic on user input
- [ ] No unbounded loops

### Tests

- [ ] New functionality has tests
- [ ] Edge cases tested
- [ ] BTT tree updated (if applicable)

______________________________________________________________________

## PR Review Issues

| Issue                   | Detection                                      |
| ----------------------- | ---------------------------------------------- |
| Missing access control  | New external functions without modifiers       |
| State after external    | `.call{}`/`transfer` followed by state changes |
| Unchecked return values | `.call()` without checking `success`           |
| Missing events          | State changes without event emission           |
| Incomplete error info   | Errors without diagnostic parameters           |
| Test coverage gaps      | New code paths without corresponding tests     |
| Breaking changes        | Interface modifications without deprecation    |
| Gas regression          | New loops, storage operations in hot paths     |

______________________________________________________________________

## Severity Classification

| Severity          | Definition                                   |
| ----------------- | -------------------------------------------- |
| **Critical (C)**  | Direct fund loss or permanent freeze         |
| **High (H)**      | Significant loss under specific conditions   |
| **Medium (M)**    | Limited loss or functionality impairment     |
| **Low (L)**       | Minor issues, deviations from best practices |
| **Informational** | Suggestions and observations                 |

______________________________________________________________________

## Quick Vulnerability Reference

> **Full checklist**: See `.claude/skills/audit/references/vulnerability-checklist.md` for comprehensive patterns.

| Severity     | Key Checks                                                                                    |
| ------------ | --------------------------------------------------------------------------------------------- |
| **Critical** | Reentrancy (CEI), Access control, Unchecked `.call()`, Delegatecall targets, Signature replay |
| **High**     | Flash loan assumptions, Oracle manipulation, Front-running, Integer overflow, Price inflation |
| **Medium**   | Fee-on-transfer tokens, Rebasing tokens, Unbounded loops, Timestamp dependence                |

______________________________________________________________________

## Comment Prefixes

| Prefix        | Meaning                          |
| ------------- | -------------------------------- |
| `BLOCKING:`   | Must fix before merge            |
| `IMPORTANT:`  | Should fix, but can be follow-up |
| `SUGGESTION:` | Nice to have, optional           |
| `NIT:`        | Minor style preference           |
| `QUESTION:`   | Clarification needed             |

______________________________________________________________________

## Protocol Invariants

Security properties that MUST always hold. **Read the authoritative invariants from the codebase.**

### Invariant README Locations

| Package | Location                           |
| ------- | ---------------------------------- |
| Lockup  | `lockup/tests/invariant/README.md` |
| Flow    | `flow/tests/invariant/README.md`   |

### What to Verify

When reviewing code, read the package's invariant README and verify:

1. **No new code violates existing invariants**
2. **New features have corresponding invariants added**
3. **State transitions follow documented valid paths**
4. **Aggregate amounts remain consistent**

### Universal Invariants (all protocols)

| Category               | Check                                     |
| ---------------------- | ----------------------------------------- |
| **Value conservation** | Total in = total out + total remaining    |
| **Monotonic state**    | Withdrawn/streamed amounts never decrease |
| **Access control**     | Only authorized roles modify state        |
| **State machine**      | Only valid transitions occur (see README) |

______________________________________________________________________

## Final Checklists

### Before Approving Any Code

- [ ] Compiles without warnings
- [ ] All tests pass
- [ ] Follows project conventions
- [ ] No obvious security issues
- [ ] Adequate test coverage

### For Security-Critical Code

- [ ] CEI pattern followed
- [ ] Access control verified
- [ ] External calls checked
- [ ] Edge cases handled
- [ ] Static analysis clean

### Before Marking Audit Complete

- [ ] All external entry points reviewed
- [ ] All state-changing functions checked for reentrancy
- [ ] Access control verified on every sensitive function
- [ ] External call return values handled
- [ ] Token integration patterns validated
- [ ] Oracle dependencies assessed
- [ ] Flash loan attack vectors considered
- [ ] Slither run with no unreviewed findings

______________________________________________________________________

## Example Invocations

Test this skill with these prompts:

1. **PR review**: "Review this PR for security issues: [diff content]"
2. **Self-review**: "Run through the self-review checklist for my new `withdraw` function"
3. **Deep review**: "Perform a security audit of the `SablierFlow.sol` contract"
4. **Invariant check**: "Verify this code doesn't violate the value conservation invariant"
