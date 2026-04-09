# Flow Protocol

Open-ended streaming with debt tracking and rate-per-second model.

## Core Formula

```
amountOwed = ratePerSecond × elapsedTime

where:
    elapsedTime = currentTime - snapshotTime
    totalDebt = snapshotDebt + amountOwed
```

______________________________________________________________________

## Debt Model

| Component          | Formula                                        |
| ------------------ | ---------------------------------------------- |
| **Ongoing debt**   | `ratePerSecond × (currentTime - snapshotTime)` |
| **Total debt**     | `snapshotDebt + ongoingDebt`                   |
| **Covered debt**   | `min(totalDebt, balance)` (withdrawable)       |
| **Uncovered debt** | `max(0, totalDebt - balance)`                  |

### Snapshot Updates

Snapshots are taken on:

- Withdraw (snapshotDebt = remaining debt, snapshotTime = now)
- Adjust rate (snapshotDebt = current debt, snapshotTime = now)
- Pause/Restart (snapshotDebt = current debt, snapshotTime = now)

______________________________________________________________________

## Statuses

| Status                  | Condition                       |
| ----------------------- | ------------------------------- |
| **PENDING**             | ratePerSecond = 0               |
| **STREAMING_SOLVENT**   | rps > 0 AND totalDebt ≤ balance |
| **STREAMING_INSOLVENT** | rps > 0 AND totalDebt > balance |
| **PAUSED_SOLVENT**      | paused AND totalDebt ≤ balance  |
| **PAUSED_INSOLVENT**    | paused AND totalDebt > balance  |
| **VOIDED**              | Permanently terminated          |

______________________________________________________________________

## Key Operations

| Operation    | Effect on State                                 |
| ------------ | ----------------------------------------------- |
| **Deposit**  | Increases balance (anyone can deposit)          |
| **Withdraw** | Decreases balance, updates snapshot             |
| **Adjust**   | Changes rps, updates snapshot                   |
| **Pause**    | Sets rps = 0, preserves debt                    |
| **Restart**  | Sets new rps, updates snapshot                  |
| **Refund**   | Sender reclaims `balance - coveredDebt`         |
| **Void**     | Permanently terminates, forfeits uncovered debt |

______________________________________________________________________

## Withdrawal Formula

```
withdrawableAmount = coveredDebt = min(totalDebt, balance)

After withdrawal:
    newBalance = balance - withdrawableAmount
    newSnapshotDebt = totalDebt - withdrawableAmount
    newSnapshotTime = currentTime
```

______________________________________________________________________

## Refund Formula

```
refundableAmount = balance - coveredDebt
                 = balance - min(totalDebt, balance)
                 = max(0, balance - totalDebt)
```

______________________________________________________________________

## Rate Adjustment

When adjusting rate from `oldRps` to `newRps`:

```
// Snapshot current debt
snapshotDebt = snapshotDebt + (oldRps × (currentTime - snapshotTime))
snapshotTime = currentTime
ratePerSecond = newRps
```

______________________________________________________________________

## NFT Mechanics

- Token ID = Stream ID
- Owner = Recipient
- Transfers change the stream recipient

______________________________________________________________________

## References

Refer to https://docs.sablier.com/llms-flow.txt for up to date documentation.
