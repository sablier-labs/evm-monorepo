---
name: handbook
user-invocable: false
description: Protocol domain knowledge - Lockup (vesting), Flow (streaming), Airdrops (merkle distribution). This skill provides context when implementing business logic, understanding protocol formulas, state transitions, or answering questions about how Sablier protocols work.
---

# Protocol Handbook

Protocol concepts essential for writing contracts and understanding business logic.

## Protocol Registry

| Protocol        | Purpose                   | Key Concept                                     | Reference                                           |
| --------------- | ------------------------- | ----------------------------------------------- | --------------------------------------------------- |
| **Lockup**      | Fixed-term token vesting  | Deposit upfront, stream over defined period     | `.claude/skills/handbook/references/lockup.md`      |
| **Flow**        | Open-ended streaming      | Rate-per-second with debt tracking, no end time | `.claude/skills/handbook/references/flow.md`        |
| **Airdrops**    | Merkle-based distribution | Recipients claim via proofs, optional vesting   | `.claude/skills/handbook/references/airdrops.md`    |
| **Comptroller** | Cross-protocol admin      | Governance, fees, hook allowlisting             | `.claude/skills/handbook/references/comptroller.md` |

> **Adding a new protocol?** See [Protocol Template](#adding-a-new-protocol) below.

## Protocol Comparison

| Aspect      | Lockup                    | Flow                         | Airdrops                |
| ----------- | ------------------------- | ---------------------------- | ----------------------- |
| End time    | Fixed at creation         | Open-ended                   | Campaign expiry         |
| Funding     | Upfront deposit required  | Flexible, anytime            | Upfront in campaign     |
| Cancelation | Refunds unstreamed tokens | Void forfeits uncovered debt | Clawback after grace    |
| NFT         | Yes (stream ID = token)   | Yes (stream ID = token)      | No                      |
| Use cases   | Vesting, airdrops         | Payroll, subscriptions       | Token launches, rewards |

## Core Patterns Across Protocols

### Value Conservation

All protocols maintain: `total_in = total_out + total_remaining`

| Protocol | Invariant                                                   |
| -------- | ----------------------------------------------------------- |
| Lockup   | `deposited = withdrawn + refunded + (streamed - withdrawn)` |
| Flow     | `balance + totalWithdrawn = totalDeposited`                 |
| Airdrops | `campaignAmount = claimed + unclaimed + clawedBack`         |

### Status State Machines

Each protocol has defined status transitions. See individual references for diagrams.

### NFT Mechanics (Lockup & Flow)

- Token ID = Stream ID
- Owner = Recipient
- Transfer changes recipient
- Transferability set at creation (Lockup) or always transferable (Flow)

______________________________________________________________________

## References

- [Lockup Protocol](.claude/skills/handbook/references/lockup.md) - Vesting streams, shapes (Linear, Dynamic, Tranched), hooks
- [Flow Protocol](.claude/skills/handbook/references/flow.md) - Debt model, rate adjustments, solvency
- [Airdrops Protocol](.claude/skills/handbook/references/airdrops.md) - Merkle campaigns, claiming, clawback
- [Comptroller](.claude/skills/handbook/references/comptroller.md) - Admin contract, governance, Comptrollerable base

______________________________________________________________________

## Adding a New Protocol

When implementing a new Sablier protocol, create a reference file following this template:

### Reference File Template

Create `.claude/skills/handbook/references/{protocol-name}.md`:

```markdown
# {Protocol Name} Protocol

{One-line description of what this protocol does.}

## Core Formula

{The mathematical model driving the protocol}

## Key Concepts

| Concept     | Description  |
| ----------- | ------------ |
| **{Term1}** | {Definition} |
| **{Term2}** | {Definition} |

## Statuses

| Status        | Condition                  |
| ------------- | -------------------------- |
| **{STATUS1}** | {When this status applies} |

## Status Transitions

{ASCII diagram of valid state transitions}

## Key Operations

| Operation | Effect on State |
| --------- | --------------- |
| **{op1}** | {What it does}  |

## Invariants

{List of properties that must always hold}

## NFT Mechanics (if applicable)

{How NFTs relate to protocol entities}

## References

Refer to https://docs.sablier.com/llms-{protocol}.txt for up-to-date documentation.
```

### Checklist for New Protocol

- [ ] Create `.claude/skills/handbook/references/{protocol}.md` following template
- [ ] Add to Protocol Registry table above
- [ ] Add to Protocol Comparison table
- [ ] Update agent's package structure in `solidity-engineer.md`
- [ ] Add protocol-specific BTT conventions to `.claude/skills/btt-testing/references/sablier-conventions.md`
- [ ] Add test conventions to `.claude/skills/foundry-testing/references/sablier-conventions.md`

______________________________________________________________________

## Example Invocations

Test this skill with these prompts:

1. **Concept question**: "Explain the difference between Lockup Linear and Lockup Dynamic streams"
2. **Formula question**: "How is the withdrawable amount calculated in Flow when a stream is insolvent?"
3. **State machine**: "What are the valid status transitions for a Lockup stream?"
4. **Business logic**: "How does the clawback mechanism work in Airdrops campaigns?"
