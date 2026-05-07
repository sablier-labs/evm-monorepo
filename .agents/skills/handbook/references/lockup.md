# Lockup Protocol

Fixed-term streaming where tokens are deposited upfront and released over time.

## Stream Shapes

| Shape        | Distribution                      | Use Case                  |
| ------------ | --------------------------------- | ------------------------- |
| **Linear**   | Constant rate with optional cliff | Standard vesting          |
| **Dynamic**  | Custom curves via segments        | Complex vesting schedules |
| **Tranched** | Discrete unlocks at timestamps    | Milestone-based releases  |

---

## Mathematical Formulas

### Lockup Linear

```
elapsedTime = currentTime - startTime
totalTime = endTime - startTime

if currentTime < cliffTime:
    streamedAmount = 0
else:
    streamedAmount = depositedAmount × (elapsedTime / totalTime)
```

### Lockup Dynamic (Segments)

**Segment struct:**

| Field       | Type      | Description                          |
| ----------- | --------- | ------------------------------------ |
| `amount`    | `uint128` | Tokens released by end of segment    |
| `exponent`  | `UD2x18`  | Curve shape (18 decimal fixed-point) |
| `timestamp` | `uint40`  | When segment ends                    |

**Streamed amount calculation:**

```
For each segment i:
    if currentTime >= segment[i].timestamp:
        // Segment complete
        segmentStreamed[i] = segment[i].amount
    else if currentTime > segment[i-1].timestamp:
        // Currently in this segment
        elapsedSegment = currentTime - segment[i-1].timestamp
        totalSegment = segment[i].timestamp - segment[i-1].timestamp
        progress = elapsedSegment / totalSegment
        segmentStreamed[i] = segment[i].amount × progress^exponent

Total streamed = sum(segmentStreamed[0..n])
```

**Exponent effects:**

| Exponent | Curve   | Distribution               |
| -------- | ------- | -------------------------- |
| `e = 1`  | Linear  | Constant rate              |
| `e > 1`  | Convex  | Back-loaded (slow → fast)  |
| `e < 1`  | Concave | Front-loaded (fast → slow) |

### Lockup Tranched (Tranches)

**Tranche struct:**

| Field       | Type      | Description                |
| ----------- | --------- | -------------------------- |
| `amount`    | `uint128` | Tokens unlocked at tranche |
| `timestamp` | `uint40`  | When tranche unlocks       |

**Streamed amount calculation:**

```
streamedAmount = 0
for each tranche:
    if currentTime >= tranche.timestamp:
        streamedAmount += tranche.amount
```

**Constraint:** Sum of all tranche amounts must equal deposited amount.

---

## Key Calculations

| Calculation      | Formula                                            |
| ---------------- | -------------------------------------------------- |
| **Streamed**     | Amount vested based on time elapsed                |
| **Withdrawable** | `streamedAmount - withdrawnAmount`                 |
| **Refundable**   | `depositedAmount - streamedAmount` (if cancelable) |

---

## Statuses

| Status        | Description                                         |
| ------------- | --------------------------------------------------- |
| **PENDING**   | Created but not started (current time < start time) |
| **STREAMING** | Actively streaming tokens                           |
| **SETTLED**   | All tokens streamed, awaiting withdrawal            |
| **CANCELED**  | Sender canceled, remaining tokens await withdrawal  |
| **DEPLETED**  | All tokens withdrawn and/or refunded                |

### Status Transitions

```
PENDING ──(time)──> STREAMING ──(time)──> SETTLED ──(withdraw all)──> DEPLETED
                        │
                        └──(cancel)──> CANCELED ──(withdraw all)──> DEPLETED
```

### Warm vs Cold

- **Warm** (PENDING, STREAMING): Time passage alone can change status
- **Cold** (SETTLED, CANCELED, DEPLETED): Requires explicit action to change

---

## State Flags

| Flag           | Description                                            |
| -------------- | ------------------------------------------------------ |
| isCancelable   | Can sender cancel? False after cancel/renounce/deplete |
| wasCanceled    | Was stream ever canceled?                              |
| isDepleted     | All tokens withdrawn?                                  |
| isTransferable | Can NFT be transferred? Immutable after creation       |

---

## Amounts Struct

| Field     | Description                                |
| --------- | ------------------------------------------ |
| deposited | Total deposited at creation                |
| withdrawn | Cumulative withdrawn by recipient          |
| refunded  | Refunded to sender on cancel (0 otherwise) |

---

## NFT Mechanics

- Token ID = Stream ID
- Owner = Recipient
- Transfers change the stream recipient
- Transferability is set at creation and immutable

---

## Recipient Hooks

Contracts can be allowlisted to receive callbacks on cancel and withdraw events.

### Interface

Implement `ISablierLockupRecipient`:

```solidity
interface ISablierLockupRecipient is IERC165 {
    function onSablierLockupCancel(
        uint256 streamId,
        address sender,
        uint128 senderAmount,
        uint128 recipientAmount
    ) external returns (bytes4 selector);

    function onSablierLockupWithdraw(
        uint256 streamId,
        address caller,
        address to,
        uint128 amount
    ) external returns (bytes4 selector);
}
```

### Implementation Requirements

| Requirement                   | Details                                                                                                    |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Return correct selector       | Must return `ISablierLockupRecipient.onSablierLockupCancel.selector` or `onSablierLockupWithdraw.selector` |
| Implement `supportsInterface` | Must return `true` for `0xf8ee98d3` (interface ID)                                                         |
| Be allowlisted                | Admin must call `allowToHook(recipientAddress, true)`                                                      |

### Hook Execution Flow

1. User calls `withdraw()` or `cancel()` on Lockup contract
2. Lockup checks if recipient is allowlisted via `isAllowedToHook()`
3. If allowlisted, Lockup calls the hook function on recipient
4. Hook must return correct selector
5. **If hook reverts or returns wrong selector, entire transaction reverts**

### Security Considerations

| Risk                           | Mitigation                             |
| ------------------------------ | -------------------------------------- |
| Hook reverts block withdrawals | Only allowlist trusted contracts       |
| Reentrancy via hooks           | Hooks called AFTER state changes (CEI) |
| Gas griefing                   | Limited gas forwarded to hooks         |

---

## References

Refer to https://docs.sablier.com/llms-lockup.txt for up to date documentation.
