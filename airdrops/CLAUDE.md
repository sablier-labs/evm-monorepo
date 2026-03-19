# Sablier Airdrops

Merkle-based token distribution with optional vesting via Lockup streams.

@../CLAUDE.md

## Protocol Overview

Distribute ERC-20 tokens using Merkle trees. Five distribution modes:

- **Execute**: Claims execute arbitrary calldata
- **Instant**: Recipients claim tokens immediately
- **LL (Lockup Linear)**: Claims create Lockup Linear streams
- **LT (Lockup Tranched)**: Claims create Lockup Tranched streams
- **VCA (Variable Claim Amount)**: Linear unlock; unvested tokens forfeited on claim

Campaign timing options:

- **Absolute**: Vesting starts at fixed timestamp for all
- **Relative**: Vesting starts when each user claims

## Package Structure

```
src/
├── SablierMerkleInstant.sol           # Instant distribution
├── SablierMerkleLL.sol                # Lockup Linear vesting
├── SablierMerkleLT.sol                # Lockup Tranched vesting
├── SablierMerkleVCA.sol               # Variable claim amount
├── SablierMerkleExecute.sol           # Execute-based campaigns
├── SablierFactoryMerkleInstant.sol    # Factory for Instant campaigns
├── SablierFactoryMerkleLL.sol         # Factory for LL campaigns
├── SablierFactoryMerkleLT.sol         # Factory for LT campaigns
├── SablierFactoryMerkleVCA.sol        # Factory for VCA campaigns
├── SablierFactoryMerkleExecute.sol    # Factory for Execute campaigns
├── abstracts/                         # Shared base contracts
├── interfaces/                        # Campaign interfaces
├── libraries/                         # Helper libraries
└── types/                             # Structs, enums
tests/
├── integration/                       # BTT-based and fuzz tests
├── invariant/                         # Invariant tests
├── unit/                              # Unit tests
└── fork/                              # Fork tests
scripts/
└── solidity/                          # Deployment scripts
```

## Commands

```bash
just airdrops::build         # Build
just airdrops::test          # Run tests
just airdrops::test-lite     # Fast tests (no optimizer)
just airdrops::coverage      # Coverage report
just airdrops::full-check    # All checks
```

## Key Concepts

- **Merkle root**: Hash of all eligible recipients and amounts
- **Campaign**: Deployed airdrop contract with fixed parameters
- **Claim**: User proves eligibility via Merkle proof
- **Expiration**: Optional deadline after which admin can claw back

## Import Paths

```solidity
import { ISablierFactoryMerkleInstant } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierFactoryMerkleLT } from "@sablier/airdrops/src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierMerkleInstant } from "@sablier/airdrops/src/interfaces/ISablierMerkleInstant.sol";
```
