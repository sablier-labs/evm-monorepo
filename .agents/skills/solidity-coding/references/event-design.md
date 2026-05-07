# Event Design for Indexers

Guide for designing events that are efficient to index (The Graph, Ponder, custom indexers).

## Event Design Principles

### 1. Include All Queryable Data

Indexers should never need to make RPC calls to reconstruct state.

```solidity
// BAD: Indexer must call contract to get details
event StreamCreated(uint256 indexed streamId);

// GOOD: All relevant data in event
event StreamCreated(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    address token,
    uint128 depositedAmount,
    uint40 startTime,
    uint40 endTime,
    bool cancelable,
    bool transferable
);
```

### 2. Use Indexed Parameters Strategically

| Limit         | Indexed Topics                               |
| ------------- | -------------------------------------------- |
| Max 3 indexed | For non-anonymous events (topic0 = selector) |
| Max 4 indexed | For anonymous events                         |

**Index these** (commonly filtered/searched):

- Entity IDs (`streamId`, `campaignId`)
- Addresses (`sender`, `recipient`, `token`)

**Don't index these** (rarely filtered, waste gas):

- Amounts (usually aggregated, not filtered)
- Timestamps (range queries not supported)
- Booleans (only 2 values, not selective)

### 3. Emit Events for All State Changes

Every state modification should emit an event:

```solidity
function cancel(uint256 streamId) external {
    // ... state changes ...

    emit CancelLockupStream(
        streamId,
        msg.sender,
        recipient,
        token,
        senderAmount,
        recipientAmount
    );
}
```

---

## Event Naming Conventions

### Format

`{Action}{Entity}` or `{Entity}{Action}`

| Pattern                 | Example                    | When to Use      |
| ----------------------- | -------------------------- | ---------------- |
| `{Action}{Entity}`      | `CreateLockupStream`       | Primary actions  |
| `{Entity}{Action}ed`    | `StreamCanceled`           | Status changes   |
| `{Entity}{Property}Set` | `StreamTransferabilitySet` | Property updates |

### Sablier Event Names

| Event                      | Parameters                                                 |
| -------------------------- | ---------------------------------------------------------- |
| `CreateLockupStream`       | Full stream data                                           |
| `WithdrawFromLockupStream` | streamId, to, token, amount                                |
| `CancelLockupStream`       | streamId, sender, recipient, senderAmount, recipientAmount |
| `TransferAdmin`            | oldAdmin, newAdmin                                         |

---

## Event Parameter Guidelines

### Required Parameters

Every event should include:

| Parameter          | Purpose                  | Indexed?                   |
| ------------------ | ------------------------ | -------------------------- |
| Entity ID          | Identify the entity      | Yes                        |
| Actor              | Who triggered the action | Yes (if multiple possible) |
| Relevant addresses | Token, recipient, etc.   | Yes (primary ones)         |
| Amounts            | Values changed           | No                         |
| Timestamps         | When applicable          | No                         |

### Computed vs Raw Values

Include both when useful for indexers:

```solidity
event WithdrawFromFlowStream(
    uint256 indexed streamId,
    address indexed to,
    address indexed token,
    address caller,
    uint128 withdrawnAmount,      // What was withdrawn
    uint128 totalDebt,            // Computed: total debt at time of withdrawal
    uint128 remainingBalance      // Computed: balance after withdrawal
);
```

### Struct Parameters

Avoid passing structs directly (ABI decoding complexity):

```solidity
// BAD: Struct in event (complex to decode)
event StreamCreated(uint256 streamId, Stream stream);

// GOOD: Flat parameters
event StreamCreated(
    uint256 indexed streamId,
    address sender,
    address recipient,
    uint128 amount,
    uint40 startTime,
    uint40 endTime
);
```

---

## The Graph Considerations

### Subgraph Schema Mapping

Design events to map cleanly to GraphQL entities:

```graphql
# schema.graphql
type Stream @entity {
  id: ID! # streamId
  sender: Bytes! # From event
  recipient: Bytes! # From event
  token: Token! # Relationship
  depositedAmount: BigInt! # From event
  withdrawnAmount: BigInt! # Updated on withdraw events
  status: StreamStatus! # Derived from events
}
```

### Event Handlers

```typescript
// mapping.ts
export function handleCreateLockupStream(event: CreateLockupStream): void {
  let stream = new Stream(event.params.streamId.toString());
  stream.sender = event.params.sender;
  stream.recipient = event.params.recipient;
  stream.token = event.params.token.toHexString();
  stream.depositedAmount = event.params.depositedAmount;
  stream.withdrawnAmount = BigInt.zero();
  stream.status = "STREAMING";
  stream.save();
}
```

### Avoiding Re-indexing

Include version or type info when events might change:

```solidity
// Include model type so subgraph can handle differently
event CreateLockupStream(
    uint256 indexed streamId,
    address indexed sender,
    Lockup.Model indexed model,  // LL, LD, or LT
    // ... rest of params
);
```

---

## Gas Optimization

### Event Gas Costs

| Component           | Gas Cost |
| ------------------- | -------- |
| Base event          | ~375     |
| Per topic (indexed) | ~375     |
| Per byte (data)     | ~8       |

### Optimization Strategies

```solidity
// If event data is large, consider splitting
// Main event for common queries
event StreamCreated(
    uint256 indexed streamId,
    address indexed sender,
    address indexed recipient,
    address token,
    uint128 amount
);

// Separate event for detailed data (only indexed if needed)
event StreamCreatedDetails(
    uint256 indexed streamId,
    uint40 startTime,
    uint40 endTime,
    bool cancelable,
    bool transferable
);
```

---

## Common Patterns

### Batch Operations

Emit individual events for each item in batch:

```solidity
function createMultiple(CreateParams[] calldata params) external {
    for (uint256 i; i < params.length; ++i) {
        uint256 streamId = _create(params[i]);

        // Emit for each stream (indexers expect this)
        emit CreateLockupStream(streamId, ...);
    }
}
```

### Status Changes

Explicit status in events helps indexers:

```solidity
event StreamStatusChanged(
    uint256 indexed streamId,
    Lockup.Status oldStatus,
    Lockup.Status newStatus
);
```

### Metadata Updates

For ERC-721 metadata changes:

```solidity
// ERC-4906 standard
event MetadataUpdate(uint256 indexed tokenId);
event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);
```

---

## Testing Events

### In Foundry Tests

```solidity
function test_EventEmitted() external {
    vm.expectEmit({ emitter: address(lockup) });
    emit CreateLockupStream(
        expectedStreamId,
        users.sender,
        users.recipient,
        address(token),
        defaults.DEPOSIT_AMOUNT,
        defaults.START_TIME,
        defaults.END_TIME,
        true,  // cancelable
        true   // transferable
    );

    lockup.createWithTimestampsLL(params);
}
```

### Event Coverage

Ensure every event is:

- [ ] Emitted in at least one test
- [ ] Parameters verified in tests
- [ ] Indexed parameters tested for filtering

---

## Anti-Patterns

| Anti-Pattern        | Problem                    | Solution                          |
| ------------------- | -------------------------- | --------------------------------- |
| Missing events      | Indexers can't track state | Emit event for every state change |
| Insufficient data   | RPC calls needed           | Include all relevant data         |
| Over-indexing       | Wasted gas                 | Only index filterable fields      |
| Struct parameters   | Complex decoding           | Use flat parameters               |
| Inconsistent naming | Confusing schema           | Follow naming convention          |
