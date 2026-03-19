# Sablier Flow

Debt tracking protocol for open-ended token streaming with no fixed end time.

@../CLAUDE.md

## Protocol Overview

Flow tracks tokens owed between parties using a rate-per-second (rps) model:

```
amount owed = rps × elapsed time
```

Key features:

- **Open-ended**: No end time, runs until paused or voided
- **Top-ups**: Fund anytime, by anyone, any amount
- **Pause/Resume**: Sender can pause; debt stops accruing
- **Void**: Permanently stops stream; forfeits uncovered debt

## Package Structure

```
src/
├── SablierFlow.sol         # Main contract
├── FlowNFTDescriptor.sol   # NFT metadata and SVG generation
├── abstracts/              # Shared base contracts
├── interfaces/             # ISablierFlow, etc.
├── libraries/              # Helpers
└── types/                  # Structs, enums
tests/
├── integration/            # BTT-based and fuzz tests
├── invariant/              # Invariant tests
└── fork/                   # Fork tests
scripts/
└── solidity/               # Deployment scripts
```

## Commands

```bash
just flow::build             # Build
just flow::test              # Run tests
just flow::test-lite         # Fast tests (no optimizer)
just flow::coverage          # Coverage report
just flow::full-check        # All checks
```

## Key Concepts

- **Rate per second (rps)**: Tokens streamed per second (18 decimals)
- **Snapshot debt**: Debt captured when stream is paused/adjusted
- **Ongoing debt**: Debt accruing in real-time
- **Total debt**: snapshot debt + ongoing debt
- **Solvent/Insolvent**: Whether balance covers total debt

## Import Path

```solidity
import { ISablierFlow } from "@sablier/flow/src/interfaces/ISablierFlow.sol";
```
