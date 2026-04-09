# BTT Examples

Examples of `.tree` files and generated test contracts.

## Basic Tree (No Nested Branches)

```
FunctionName_Integration_Concrete_Test
├── when a is zero
│  └── it should return b
└── when b is zero
   └── it should return a
```

**Generated**: `test_WhenAIsZero()`, `test_WhenBIsZero()`

### Test Implementation with Comments

Each test function must have a comment as its first line, matching the leaf node from the tree:

```solidity
function test_WhenAIsZero() external {
    // It should return b.
    uint256 result = contract.myFunction(0, 5);
    assertEq(result, 5, "should return b when a is zero");
}

function test_WhenBIsZero() external {
    // It should return a.
    uint256 result = contract.myFunction(5, 0);
    assertEq(result, 5, "should return a when b is zero");
}
```

The comment format is: `// It should {branch text}.` (capitalized "It", period at end)

______________________________________________________________________

## Nested Branches (Generates Modifiers)

```
FunctionName_Integration_Concrete_Test
├── when a is zero
│  └── it should revert
└── when a is not zero
   ├── when a not exceed 10
   │  └── it should return 0
   └── when a exceeds 10
      └── it should return 10
```

**Generated**:

- `test_RevertWhen_AIsZero()` - no modifier
- `test_WhenANotExceed10() whenAIsNotZero` - has modifier
- `test_WhenAExceeds10() whenAIsNotZero` - has modifier

______________________________________________________________________

## Multiple Functions (Same Contract)

Use `ContractName::FunctionName` syntax:

```
ContractName::FunctionA_Integration_Concrete_Test
├── when a is zero
│  └── it should revert
└── when a is not zero
   └── it should return 10

ContractName::FunctionB_Integration_Concrete_Test
├── when b is zero
│  └── it should revert
└── when b is not zero
   └── it should return 20
```

**Generated**: Single contract with prefixed function names.

______________________________________________________________________

## Duplicate Branch Names

When same branch name appears under different parents, bulloak disambiguates:

```
FunctionA_Integration_Concrete_Test
├── when a is zero
│  └── when b is zero
│     └── it should return 0
└── when a is not zero
   └── when b is zero
      └── it should return 1
```

**Generated**: `test_WhenBIsZero()` and `test_WhenBIsZero_WhenAIsNotZero()`
