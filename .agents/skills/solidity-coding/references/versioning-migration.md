# Interface Versioning & Migration Patterns

Guide for managing breaking changes and migrating between contract versions.

## Interface Versioning

### Semantic Versioning for Contracts

| Version Bump              | When to Use                                        |
| ------------------------- | -------------------------------------------------- |
| **Major (1.0 → 2.0)**     | Breaking interface changes, storage layout changes |
| **Minor (1.0 → 1.1)**     | New functions added (backwards compatible)         |
| **Patch (1.0.0 → 1.0.1)** | Bug fixes, gas optimizations (no interface change) |

### Breaking vs Non-Breaking Changes

**Breaking Changes** (require major version):

- Removing or renaming functions
- Changing function signatures (params, return types)
- Changing event signatures
- Reordering storage variables
- Changing error selectors

**Non-Breaking Changes** (minor version):

- Adding new functions
- Adding new events
- Adding new errors
- Adding optional parameters with defaults

### Interface Identification

Use ERC-165 for interface detection:

```solidity
interface ISablierLockupV2 is IERC165 {
    // Interface ID: 0x12345678
    // Computed as XOR of all function selectors
}

contract SablierLockupV2 is ISablierLockupV2 {
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == type(ISablierLockupV2).interfaceId
            || interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }
}
```

______________________________________________________________________

## Migration Patterns

### Pattern 1: Parallel Deployment (Recommended)

Deploy new version alongside old. Let users migrate at their own pace.

```
V1 Contract (0x111...)  ←── Existing streams continue
V2 Contract (0x222...)  ←── New streams use V2
```

**Advantages**:

- No forced migration
- Zero downtime
- Users choose when to migrate
- Old streams continue to work

**Implementation**:

```solidity
// Frontend/SDK handles version routing
function getContract(uint256 streamId) external view returns (address) {
    if (streamId < V2_START_ID) {
        return address(v1);
    }
    return address(v2);
}
```

### Pattern 2: Migration Function

For stateful migrations where data must move:

```solidity
contract SablierLockupV2 {
    ISablierLockupV1 public immutable V1;

    /// @notice Migrate a stream from V1 to V2
    /// @dev Caller must be stream recipient and own the NFT
    function migrateFromV1(uint256 v1StreamId) external returns (uint256 v2StreamId) {
        // 1. Verify caller owns V1 stream
        require(V1.ownerOf(v1StreamId) == msg.sender, "Not owner");

        // 2. Get V1 stream data
        Lockup.Stream memory v1Stream = V1.getStream(v1StreamId);

        // 3. Withdraw all available from V1
        uint128 withdrawable = V1.withdrawableAmountOf(v1StreamId);
        if (withdrawable > 0) {
            V1.withdrawMax(v1StreamId, msg.sender);
        }

        // 4. Cancel V1 stream (returns remaining to sender)
        V1.cancel(v1StreamId);

        // 5. Create equivalent V2 stream
        v2StreamId = _createV2Stream(v1Stream, msg.sender);

        emit StreamMigrated(v1StreamId, v2StreamId, msg.sender);
    }
}
```

### Pattern 3: Wrapper/Adapter

Wrap old contract with new interface:

```solidity
contract LockupV2Adapter is ISablierLockupV2 {
    ISablierLockupV1 public immutable V1;

    /// @inheritdoc ISablierLockupV2
    function withdraw(
        uint256 streamId,
        address to,
        uint128 amount
    ) external override returns (uint128 withdrawnAmount) {
        // Adapt V1 call to V2 interface
        return V1.withdrawFromStream(streamId, amount);
    }

    // New V2-only functions revert or return defaults
    function newV2Function() external pure override {
        revert("Not supported in V1 adapter");
    }
}
```

______________________________________________________________________

## Storage Migration (Upgradeable Contracts)

### Storage Layout Rules

1. **Never remove variables** - Mark as deprecated instead
2. **Never reorder variables** - New variables go at end
3. **Never change types** - Even if "compatible" (uint256 → uint128)
4. **Always use storage gaps** in base contracts

### Storage Gap Pattern

```solidity
abstract contract SablierLockupStateV1 {
    mapping(uint256 => Stream) internal _streams;
    uint256 internal _nextStreamId;

    // Reserve 50 slots for future variables
    uint256[50] private __gap;
}

abstract contract SablierLockupStateV2 is SablierLockupStateV1 {
    // New variable uses gap slot
    mapping(uint256 => ExtendedData) internal _extendedData;

    // Gap reduced by 1
    uint256[49] private __gap;
}
```

### Checking Storage Layout

```bash
# Generate storage layout
forge inspect SablierLockupV1 storage-layout --pretty > v1-layout.txt
forge inspect SablierLockupV2 storage-layout --pretty > v2-layout.txt

# Compare layouts
diff v1-layout.txt v2-layout.txt
```

### Safe Migration Script

```solidity
contract MigrateV1ToV2 is Script {
    function run(address proxy) public {
        // 1. Verify current implementation
        address currentImpl = ERC1967Utils.getImplementation(proxy);
        require(currentImpl == V1_IMPL, "Unexpected implementation");

        // 2. Verify storage compatibility (off-chain check)
        // Compare storage layouts before proceeding

        // 3. Deploy new implementation
        SablierLockupV2 newImpl = new SablierLockupV2();

        // 4. Upgrade
        vm.broadcast();
        UUPSUpgradeable(proxy).upgradeTo(address(newImpl));

        // 5. Run migration initializer if needed
        SablierLockupV2(proxy).initializeV2(migrationParams);
    }
}
```

______________________________________________________________________

## Deprecation Strategy

### Deprecation Timeline

| Phase                | Duration  | Actions                         |
| -------------------- | --------- | ------------------------------- |
| **Announcement**     | Week 0    | Blog post, Discord, Twitter     |
| **Soft Deprecation** | Weeks 1-4 | Warnings in UI, docs updated    |
| **Hard Deprecation** | Weeks 5-8 | V1 UI disabled, V2 default      |
| **Sunset**           | Week 12+  | V1 contracts remain, no support |

### On-Chain Deprecation Notice

```solidity
contract SablierLockupV1 {
    bool public constant DEPRECATED = true;
    address public constant SUCCESSOR = 0x222...;

    /// @notice This version is deprecated. Use V2 at SUCCESSOR address.
    function create(...) external returns (uint256) {
        emit DeprecationWarning(msg.sender, SUCCESSOR);
        // Still works, just warns
        return _create(...);
    }
}
```

### Frontend Handling

```typescript
async function getStreamContract(streamId: bigint): Promise<Contract> {
  // Check which version owns this stream
  if (await v1.exists(streamId)) {
    console.warn("Stream is on deprecated V1 contract");
    return v1;
  }
  return v2;
}
```

______________________________________________________________________

## Error Catalog Management

### Cross-Version Error Compatibility

Maintain error selector stability when possible:

```solidity
// V1: Custom error
error SablierLockup_Overdraw(uint256 streamId, uint128 amount, uint128 available);
// Selector: 0xabcd1234

// V2: Same signature = same selector (compatible)
error SablierLockup_Overdraw(uint256 streamId, uint128 amount, uint128 available);

// V2 alternative: New error for different behavior
error SablierLockupV2_InsufficientBalance(uint256 streamId, uint128 requested, uint128 balance);
```

### Error Documentation

Maintain a cross-version error reference:

```markdown
## Error Selector Reference

| Selector   | V1  | V2  | Description      |
| ---------- | --- | --- | ---------------- |
| 0xabcd1234 | ✓   | ✓   | Overdraw attempt |
| 0xef567890 | ✓   | ✗   | Removed in V2    |
| 0x12345678 | ✗   | ✓   | New in V2        |
```

______________________________________________________________________

## Testing Migrations

### Migration Test Pattern

```solidity
contract MigrationTest is Test {
    function test_MigrationPreservesState() external {
        // 1. Create V1 stream
        uint256 v1Id = v1.create(params);

        // 2. Advance time, do some withdrawals
        vm.warp(block.timestamp + 30 days);
        v1.withdraw(v1Id, recipient, 1000e18);

        // 3. Migrate
        uint256 v2Id = v2.migrateFromV1(v1Id);

        // 4. Verify state preserved
        assertEq(v2.getDeposited(v2Id), v1Deposited);
        assertEq(v2.getWithdrawn(v2Id), v1Withdrawn);
        assertEq(v2.getRecipient(v2Id), v1Recipient);
    }

    function test_OldStreamsStillWork() external {
        // Verify V1 streams continue to function after V2 deployment
        uint256 v1Id = v1.create(params);

        // Deploy V2 (simulating production upgrade)
        deployV2();

        // V1 stream still works
        vm.warp(block.timestamp + 30 days);
        v1.withdraw(v1Id, recipient, 1000e18); // Should succeed
    }
}
```
