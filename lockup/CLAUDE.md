# Sablier Lockup

Token distribution protocol for onchain vesting and airdrops with fixed-term streams.

@../CLAUDE.md

## Protocol Overview

Lockup enables depositing ERC-20 tokens that are progressively allocated to recipients over time. Key models:

- **Linear**: Constant streaming rate from start to end
- **Dynamic**: Custom curves with multiple segments
- **Tranched**: Discrete unlocks at specified timestamps

Uses singleton architecture - all streams managed in `SablierLockup` contract.

## Package Structure

```
src/
├── SablierLockup.sol           # Main contract
├── SablierBatchLockup.sol      # Batch stream creation
├── LockupNFTDescriptor.sol     # NFT metadata and SVG generation
├── abstracts/                  # Shared base contracts
├── interfaces/                 # ISablierLockup, etc.
├── libraries/                  # Helpers, SVG generation
└── types/                      # Structs, enums
tests/
├── integration/                # BTT-based and fuzz tests
├── invariant/                  # Invariant tests
├── unit/                       # Unit tests
└── fork/                       # Fork tests
scripts/
└── solidity/                   # Deployment scripts
```

## Commands

```bash
just lockup::build           # Build
just lockup::test            # Run tests
just lockup::test-lite       # Fast tests (no optimizer)
just lockup::coverage        # Coverage report
just lockup::full-check      # All checks
```

## Key Concepts

- **Stream ID**: NFT representing the stream (ERC-721)
- **Cliff**: Optional period before streaming begins
- **Cancelable**: Sender can cancel and reclaim unstreamed tokens
- **Transferable**: Recipient can transfer the stream NFT

## Import Path

```solidity
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
```
