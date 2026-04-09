# Sablier BTT Conventions

This reference contains Sablier-specific BTT examples and conventions that extend the generic patterns in the main
skill.

## Sablier Test Directory Structure

"tests/integration/concrete/{function-name}/{functionName}.tree"

```
FunctionName_Integration_Concrete_Test
├── withdraw/
│  ├── withdraw.tree
│  └── withdraw.t.sol
├── create-with-timestamps-ll/
│  ├── createWithTimestampsLL.tree
│  └── createWithTimestampsLL.t.sol
└── ...
```

## Sablier Terminology (few examples)

| Concept              | BTT Branch                  |
| -------------------- | --------------------------- |
| Stream doesn't exist | `given null`                |
| Stream exists        | `given not null`            |
| Stream depleted      | `given stream depleted`     |
| Stream not depleted  | `given stream not depleted` |
| Stream cancelable    | `given stream cancelable`   |
| Caller is sender     | `when caller sender`        |
| Caller is recipient  | `when caller recipient`     |
| Caller is unknown    | `when caller unknown`       |

## Sablier Happy Path Examples

### Flow Withdraw

```
└── it should make the withdrawal
   ├── it should reduce the stream balance by the withdrawn amount
   ├── it should reduce the aggregate amount by the withdrawn amount
   ├── it should update snapshot debt
   ├── it should update snapshot time to current time
   └── it should emit {Transfer}, {WithdrawFromFlowStream} and {MetadataUpdate} events
```

### Lockup Withdraw

```
└── it should make the withdrawal
   ├── it should mark the stream as depleted
   ├── it should make the stream not cancelable
   ├── it should update the withdrawn amount
   ├── it should reduce the aggregate amount
   └── it should emit {Transfer}, {WithdrawFromLockupStream} and {MetadataUpdate} events
```

### Lockup Cancel

```
└── it should cancel the stream
   ├── it should mark the stream as canceled
   ├── it should make the stream not cancelable
   ├── it should set the refunded amount
   ├── it should refund the sender
   ├── it should reduce the aggregate amount
   ├── it should emit {Transfer} event
   └── it should emit {CancelLockupStream} event
```

### Airdrop Claim

```
└── it should claim
   ├── it should mark the index as claimed
   ├── it should create the lockup stream
   └── it should emit {Claim} event
```

## Sablier State Condition Order

For Sablier streams, typical guard condition order:

```
FunctionName_Integration_Concrete_Test
├── when delegate call
│  └── it should revert
└── when no delegate call
   ├── given null
   │  └── it should revert
   └── given not null
      ├── given stream depleted
      │  └── it should revert
      └── given stream not depleted
         ├── when caller unknown
         │  └── it should revert
         └── when caller authorized
            └── ...
```

## Sablier Model-Specific Trees

When testing model-specific behavior (Linear, Dynamic, Tranched):

```
StreamedAmountOf_Integration_Concrete_Test
├── given model LL
│  ├── when current time before cliff
│  │  └── it should return zero
│  └── when current time after cliff
│     └── it should return correct streamed amount
├── given model LD
│  └── ...
└── given model LT
   └── ...
```

## Running Bulloak in Sablier Repos

```bash
# Scaffold tests in monorepo
just test-bulloak <package>

# Or directly
bulloak scaffold -wf --skip-modifiers --format-descriptions lockup/tests/integration/concrete/withdraw/withdraw.tree
```
