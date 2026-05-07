# Audit Workflow Guide

Step-by-step process for smart contract security audits. Find examples in the codebase.

---

## Pre-Audit Preparation

### Scope Definition

- [ ] Identify all contracts in scope
- [ ] Note out-of-scope contracts (dependencies, forks)
- [ ] Clarify finding types desired (security only? gas? code quality?)
- [ ] Understand deployment context (mainnet, L2, specific chains)

### Documentation Review

- [ ] Read protocol documentation/whitepaper
- [ ] Review existing specifications or READMEs
- [ ] Check for previous audit reports
- [ ] Understand the protocol's economic model

---

## Phase 1: Reconnaissance

### Map Attack Surface

Document for each contract:

| Function | Visibility | State Changes | External Calls | Access Control |
| -------- | ---------- | ------------- | -------------- | -------------- |

### Identify Value Flows

1. **Entry points**: Where do tokens/ETH enter?
2. **Storage**: Where is value tracked?
3. **Exit points**: Where do tokens/ETH leave?
4. **Intermediaries**: What contracts handle value in transit?

### Trust Boundaries

- [ ] Admin/Owner capabilities
- [ ] External contract dependencies
- [ ] Oracle trust assumptions
- [ ] User-to-user trust (if any)

---

## Phase 2: Automated Analysis

### Pattern Search

```bash
# Dangerous patterns
grep -rn "delegatecall" src/
grep -rn "selfdestruct" src/
grep -rn "tx.origin" src/
grep -rn "ecrecover" src/
grep -rn "assembly" src/
grep -rn "unchecked" src/
```

### Static Analysis

```bash
slither src/ --exclude-dependencies
forge coverage --report summary
```

---

## Phase 3: Manual Review

### Per-Function Analysis

For EACH external/public function:

- [ ] Reentrancy safe?
- [ ] Access control correct?
- [ ] Input validation sufficient?
- [ ] Return values handled?
- [ ] Edge cases covered?

### State Machine Analysis

1. **Enumerate states**: What are all possible states?
2. **Map transitions**: What moves the system between states?
3. **Check invariants**: What must always be true?
4. **Find violations**: Can invalid states be reached?

### Economic Analysis (DeFi)

- [ ] Can users extract more value than deposited?
- [ ] Are reward calculations correct?
- [ ] Can liquidations be blocked or gamed?
- [ ] Are oracle prices manipulation-resistant?
- [ ] Do flash loans break any assumptions?

---

## Phase 4: Attack Scenarios

### Threat Actors

1. **Anonymous attackers**: Flash loans, sandwiching, griefing
2. **Protocol users**: Gaming mechanics, extracting excess value
3. **Privileged actors**: Malicious admin, compromised keys
4. **External dependencies**: Oracle failure, integrated protocol exploit

### Attack Pattern Template

```
1. [Attacker action]
2. [System response]
3. [Exploitation step]
4. [Result: funds drained/state corrupted]
```

---

## Phase 5: Finding Documentation

### Severity Matrix

| Severity | Likelihood | Impact    |
| -------- | ---------- | --------- |
| Critical | Any        | Fund loss |
| High     | High       | High      |
| High     | Medium     | Critical  |
| Medium   | High       | Medium    |
| Medium   | Medium     | High      |
| Low      | High       | Low       |
| Low      | Medium     | Medium    |

### Finding Template

```markdown
## [SEVERITY-ID] Title

### Description

[Clear explanation of vulnerability]

### Impact

[What can an attacker achieve?]

### Location

`src/Contract.sol:L42-L56`

### Proof of Concept

[Steps to reproduce]

### Recommendation

[Specific fix]
```

### Quality Checks

- [ ] Root cause clearly identified?
- [ ] Impact concrete and realistic?
- [ ] POC reproducible?
- [ ] Mitigation specific and correct?
- [ ] Similar issues in other locations identified?

---

## Phase 6: Report Assembly

### Report Structure

1. **Executive Summary**: Total findings, critical issues, overall assessment
2. **Findings Table**: ID, Title, Severity, Status
3. **Detailed Findings**: Full description, location, POC, fix
4. **Gas Optimizations**: (if in scope)

---

## Post-Audit

### Fix Review Checklist

- [ ] Does the fix address the root cause?
- [ ] Does the fix introduce new issues?
- [ ] Is the fix complete (all instances)?
- [ ] Do tests cover the fixed behavior?
