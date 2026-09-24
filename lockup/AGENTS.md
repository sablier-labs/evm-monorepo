# Sablier Lockup

Token distribution protocol for onchain vesting and airdrops with fixed-term streams.

## Protocol Overview

Lockup enables depositing ERC-20 tokens that are progressively allocated to recipients over time. Key models:

- **Linear**: Constant streaming rate from start to end
- **Dynamic**: Custom curves with multiple segments
- **Tranched**: Discrete unlocks at specified timestamps

Uses singleton architecture - all streams managed in `SablierLockup` contract.

## Key Concepts

- **Stream ID**: NFT representing the stream (ERC-721)
- **Cliff**: Optional period before streaming begins
- **Cancelable**: Sender can cancel and reclaim unstreamed tokens
- **Transferable**: Recipient can transfer the stream NFT

## Import Path

```solidity
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
```
