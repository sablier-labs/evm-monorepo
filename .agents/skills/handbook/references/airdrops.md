# Airdrops Protocol

Merkle-based token distribution with optional vesting.

## Campaign Types

| Type                    | Description                                                 |
| ----------------------- | ----------------------------------------------------------- |
| **Instant**             | Tokens transferred immediately on claim                     |
| **Vested (Ranged)**     | Creates Lockup stream, vesting starts at fixed time for all |
| **Vested (Non-Ranged)** | Creates Lockup stream, vesting starts when recipient claims |
| **Variable Claim**      | Early withdrawal allowed with forfeit of unvested portion   |

## Merkle Claims

- Campaign stores only merkle root (gas efficient)
- Recipients prove eligibility via merkle proofs
- Recipients pay gas for their own claims

### Merkle Tree Structure

**Leaf node format:**

```
leaf = keccak256(abi.encodePacked(index, recipient, amount))
```

| Field       | Type      | Description                    |
| ----------- | --------- | ------------------------------ |
| `index`     | `uint256` | Unique identifier (0, 1, 2...) |
| `recipient` | `address` | Claimant's address             |
| `amount`    | `uint128` | Tokens to receive              |

### Claim Process

1. User provides: `index`, `recipient`, `amount`, `merkleProof`
2. Contract computes leaf: `keccak256(abi.encodePacked(index, recipient, amount))`
3. Contract verifies: `MerkleProof.verify(proof, root, leaf)`
4. Contract checks: `!isClaimed(index)` via bitmap
5. Contract marks claimed and transfers tokens

### Bitmap Tracking

Uses `BitMaps.BitMap` for gas-efficient claim tracking:

```solidity
// Check if claimed
bool claimed = _claimedBitMap.get(index);

// Mark as claimed
_claimedBitMap.set(index);
```

**Gas savings:** 256 claims per storage slot vs 1 per slot with mapping.

### Generating Merkle Trees (Off-chain)

Use OpenZeppelin's `@openzeppelin/merkle-tree` library:

```javascript
const { StandardMerkleTree } = require("@openzeppelin/merkle-tree");

const values = [
  [0, "0xRecipient1", "1000000000000000000"], // index, address, amount
  [1, "0xRecipient2", "2000000000000000000"],
];

const tree = StandardMerkleTree.of(values, ["uint256", "address", "uint128"]);
const root = tree.root; // Deploy campaign with this root
const proof = tree.getProof(0); // Proof for index 0
```

## Clawback

A campaign creator can clawback the unclaimed tokens after a **7-day grace period** which begins after the first claim.

- Campaign creator can retrieve misconfigured funds
- Protects against deployment errors
- After grace period, unclaimed allocations remain locked

ALternatively, the campaign creator can reclaim the forfeited tokens after the expiration of the campaign.

## References

Refer to https://docs.sablier.com/llms-airdrops.txt for up-to-date documentation on Airdrops.
