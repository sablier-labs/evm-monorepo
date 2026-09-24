# Sablier Flow

Debt tracking protocol for open-ended token streaming with no fixed end time.

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
