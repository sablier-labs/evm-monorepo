# Sablier Airdrops

Merkle-based token distribution with optional vesting via Lockup streams.

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
