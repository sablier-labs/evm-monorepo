---
coordination: exempt
name: handbook
user-invocable: false
description:
  Protocol domain knowledge - Lockup (vesting), Flow (streaming), Airdrops (merkle distribution). This skill provides
  context when implementing business logic, understanding protocol formulas, state transitions, or answering questions
  about how Sablier protocols work.
---

# Protocol Handbook

This skill is coordination-exempt: skip the ai-coord gate for its declared work.

Protocol concepts essential for writing contracts and understanding business logic.

## Protocol Registry

| Protocol        | Purpose                   | Key Concept                                     | Reference                   |
| --------------- | ------------------------- | ----------------------------------------------- | --------------------------- |
| **Lockup**      | Fixed-term token vesting  | Deposit upfront, stream over defined period     | `references/lockup.md`      |
| **Flow**        | Open-ended streaming      | Rate-per-second with debt tracking, no end time | `references/flow.md`        |
| **Airdrops**    | Merkle-based distribution | Recipients claim via proofs, optional vesting   | `references/airdrops.md`    |
| **Comptroller** | Cross-protocol admin      | Governance, fees, hook allowlisting             | `references/comptroller.md` |

Bob and Escrow (both in `bob/`) intentionally have no handbook reference; do not flag this as a gap or create one. For
their concepts, read `bob/AGENTS.md` and the package source.

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

---

## References

- [Lockup Protocol](references/lockup.md) - Vesting streams, shapes (Linear, Dynamic, Tranched), hooks
- [Flow Protocol](references/flow.md) - Debt model, rate adjustments, solvency
- [Airdrops Protocol](references/airdrops.md) - Merkle campaigns, claiming, clawback
- [Comptroller](references/comptroller.md) - Admin contract, governance, Comptrollerable base

---

## Output

Answer from the relevant reference and name the file used. When a reference conflicts with the package source, trust the
source and say so.

---

## Adding a New Protocol

When implementing a new Sablier protocol, create a reference file following this template:

### Reference File Template

Create `references/{protocol-name}.md`:

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

- [ ] Create `references/{protocol}.md` following template
- [ ] Add to Protocol Registry table above
- [ ] Add to Protocol Comparison table
- [ ] Add the package to the monorepo structure in the root `AGENTS.md`
- [ ] Add BTT and test conventions to `.agents/skills/foundry-testing/references/sablier-conventions.md`
