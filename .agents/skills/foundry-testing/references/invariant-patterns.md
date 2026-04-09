# Invariant Test Patterns

Architecture and patterns for stateful invariant testing. Find examples in `tests/invariant/`.

## Architecture

```
tests/invariant/
├── handlers/           # State manipulation contracts
│   ├── BaseHandler.sol # Shared modifiers and state
│   ├── CreateHandler.sol
│   └── ActionHandler.sol
├── stores/             # State tracking contracts
│   └── Store.sol
└── Invariant.t.sol     # Main test contract
```

______________________________________________________________________

## Handler Pattern

Handlers manipulate protocol state with bounded fuzzed inputs.

### BaseHandler Template

```solidity
abstract contract BaseHandler is Fuzzers, StdCheats {
    uint256 internal constant MAX_ENTRIES = 300;

    mapping(string func => uint256 calls) public calls;
    uint256 public totalCalls;

    modifier adjustTimestamp(uint256 seed) {
        uint256 jump = _bound(seed, 2 minutes, 40 days);
        skip(jump);
        _;
    }

    modifier checkUsers(address user1, address user2) {
        vm.assume(user1 != address(0) && user2 != address(0));
        vm.assume(user1 != address(this) && user2 != address(this));
        vm.assume(user1 != address(protocol) && user2 != address(protocol));
        _;
    }

    modifier instrument(string memory name) {
        calls[name]++;
        totalCalls++;
        _;
    }

    modifier useNewSender(address sender) {
        setMsgSender(sender);
        _;
    }
}
```

### Handler Rules

| Rule                                  | Reason                  |
| ------------------------------------- | ----------------------- |
| Early return if preconditions not met | Avoid wasting fuzz runs |
| Use `instrument` modifier             | Track call distribution |
| Bound ALL fuzzed inputs               | Prevent invalid states  |
| Record gas usage                      | Enable gas invariants   |

______________________________________________________________________

## Store Pattern

Stores track aggregate state for invariant assertions.

### Store Template

```solidity
contract Store {
    uint256 public lastEntryId;
    uint256[] public entryIds;

    mapping(uint256 id => address) public owners;
    mapping(uint256 id => Status) public previousStatus;
    mapping(uint256 id => bool) public isStatusRecorded;

    function pushEntry(uint256 id, address owner) external {
        entryIds.push(id);
        owners[id] = owner;
        lastEntryId = id;
    }

    function updateOwner(uint256 id, address newOwner) external {
        owners[id] = newOwner;
    }

    function updatePreviousStatus(uint256 id, Status status) external {
        previousStatus[id] = status;
    }
}
```

### Store Rules

| Rule                  | Reason                       |
| --------------------- | ---------------------------- |
| Track IDs in array    | Iterate for invariant checks |
| Track owners/senders  | Verify access control        |
| Track previous status | Verify state transitions     |

______________________________________________________________________

## Main Test Contract

```solidity
contract Invariant_Test is Base_Test, StdInvariant {
    Handler internal handler;
    Store internal store;

    function setUp() public override {
        Base_Test.setUp();

        store = new Store();
        handler = new Handler(token, store, protocol);

        // Target ONLY handlers
        targetContract(address(handler));

        // Exclude protocol and infrastructure
        excludeSender(address(handler));
        excludeSender(address(protocol));
        excludeSender(address(store));
    }

    function invariant_Example() external view {
        uint256 lastId = store.lastEntryId();
        for (uint256 i = 0; i < lastId; ++i) {
            uint256 id = store.entryIds(i);
            // Assert invariant for each entry
        }
    }
}
```

______________________________________________________________________

## Common Invariant Categories

| Category      | Pattern                                               |
| ------------- | ----------------------------------------------------- |
| **Balance**   | `aggregateAmount == sum(deposits) - sum(withdrawals)` |
| **Monotonic** | `withdrawn[id]` never decreases                       |
| **Status**    | Only valid transitions occur                          |
| **Bounds**    | `deposited >= streamed >= withdrawable`               |
| **Non-zero**  | Required fields are never zero                        |

______________________________________________________________________

## Status Transition Invariants

Track valid state machine transitions:

```solidity
function invariant_StatusTransitions() external {
    for (uint256 i = 0; i < store.lastEntryId(); ++i) {
        uint256 id = store.entryIds(i);
        Status current = protocol.statusOf(id);

        if (!store.isStatusRecorded(id)) {
            store.updateIsStatusRecorded(id);
            continue;
        }

        Status previous = store.previousStatus(id);

        // Assert valid transitions only
        if (previous == Status.PENDING) {
            assertNotEq(current, Status.DEPLETED);
        } else if (previous == Status.DEPLETED) {
            assertEq(current, Status.DEPLETED); // Terminal state
        }

        store.updatePreviousStatus(id, current);
    }
}
```

______________________________________________________________________

## Handler Action Pattern

```solidity
function action(
    uint256 timeJumpSeed,
    uint256 entryIndexSeed,
    uint128 amount
)
    external
    instrument("action")
    adjustTimestamp(timeJumpSeed)
    useNewSender(owner)
{
    // 1. Early return if no entries exist
    if (store.lastEntryId() == 0) return;

    // 2. Select random entry
    uint256 index = _bound(entryIndexSeed, 0, store.entryIds.length - 1);
    uint256 entryId = store.entryIds(index);

    // 3. Bound amount to valid range
    uint128 maxAmount = protocol.withdrawableAmountOf(entryId);
    if (maxAmount == 0) return;
    amount = boundUint128(amount, 1, maxAmount);

    // 4. Execute action
    uint256 gasBefore = gasleft();
    protocol.withdraw(entryId, owner, amount);
    store.recordGasUsage(entryId, Action.WITHDRAW, gasBefore - gasleft());
}
```

______________________________________________________________________

## Foundry Configuration

```toml
[invariant]
runs = 256
depth = 15
fail_on_revert = false
```

| Setting          | Purpose                                      |
| ---------------- | -------------------------------------------- |
| `runs`           | Number of fuzzing campaigns                  |
| `depth`          | Calls per campaign                           |
| `fail_on_revert` | `false` allows handlers to revert gracefully |
