---
name: btt-testing
user-invocable: true
description: Write bulloak tree specifications (.tree files) for smart contract integration tests. Trigger phrases - write a tree, create test tree, BTT spec, bulloak tree, Branching Tree Technique, or when writing integration tests for contract functions.
---

# Branching Tree Technique (BTT) Skill

Write bulloak tree specifications for smart contract tests.

## Bundled References

| Reference                                                      | Content                                   | When to Read                  |
| -------------------------------------------------------------- | ----------------------------------------- | ----------------------------- |
| `.claude/skills/btt-testing/references/examples.md`            | Complete tree and generated test examples | When learning BTT syntax      |
| `.claude/skills/btt-testing/references/sablier-conventions.md` | Sablier-specific terminology and examples | When working in Sablier repos |

## What is Bulloak?

Bulloak is a Solidity test generator that creates test scaffolds from `.tree` specification files. It offers a
structured approach to test case design that ensures comprehensive coverage of all possible scenarios and edge cases in
your smart contract tests.

## Commands

### To install Bulloak, if not found

```bash
cargo install bulloak
```

### Generate test contract from a .tree file

```bash
bulloak scaffold -wf --skip-modifiers --format-descriptions <path/to/file.tree>
```

where:

- `--format-descriptions` capitalizes the first letter of the branch in the test contract and add a period at the end of
  it.
- `--skip-modifiers` skips the generation of modifiers. We do this because we put all the modifiers in a separate
  `Modifiers.sol` file.

### Check if the code in .t.sol file matches the specification in the .tree file

```bash
bulloak check --skip-modifiers <path/to/file.tree>
```

### Important: Tree Files Should NOT Have Periods

Tree files should **not** have periods at the end of `it` branches. The `--format-descriptions` flag automatically:

1. Capitalizes the first letter
2. Adds a period at the end

```
# Correct (no period)
└── it should revert

# Wrong (has period)
└── it should revert.
```

## Tree Syntax

### Structure

```
FunctionName_ContractName_Integration_Test
├── condition1
│  └── outcome1
└── condition2
   └── outcome2
```

### Terminology

| Keyword | Purpose                                      |
| ------- | -------------------------------------------- |
| `when`  | Conditional branch (user input or timestamp) |
| `given` | Pre-condition contract state branch          |
| `it`    | Action/assertion (leaf node)                 |

- `when` and `given` become modifiers if they have nested branches.

### Spec

1. In case of single tree per file, the root should be just the function name followed by `_Integration_Concrete_Test`.
2. In case of multiple trees in the same file, each root must be `Contract::function`, using `::` as a separator, and
   all roots must share the same contract name (e.g., `Foo::hashPair`, `Foo::min`).
3. bulloak expects you to use ├ and └ characters to denote branches
4. If a branch starts with either `when` or `given`, it is a condition. `when` and `given` are interchangeable.
5. If a branch starts with `it`, it is an action. Any child branch an action has is called an action description.

## Examples

For examples, see [examples](.claude/skills/btt-testing/references/examples.md).

## Rules

1. The test file must be placed in the `tests/integration/concrete/{function}` directory.
2. The directory name must use `-` format. For example, if the function name is `createFlowStream`, the corrresponding
   test tree and test file must be placed in the `tests/integration/concrete/create-flow-stream` directory.
3. The tree file name must be `{function}.tree`.
4. The test file name must be `{function}.t.sol`.
5. The root node of the spec and the Contract name must be `{FunctionName}_Integration_Concrete_Test`.

## Workflow

### 1. Create the Tree File

Location for tree file: `tests/integration/concrete/{function-name}/{functionName}.tree`

> **Note**: Your repo's agent will provide the exact directory structure.

### 2. Generate Test Scaffold

```bash
bulloak scaffold -wf --skip-modifiers --format-descriptions <path/to/file.tree>
```

This generates a `.t.sol` file.

### 3. Check Tree-Test Alignment

```bash
bulloak check --skip-modifiers <path/to/file.tree>
```

If it returns false, your repo agent will look into it and fix the issues.

## Best Practices

### 1. Order Conditions Logically

Start with guard conditions that cause early reverts:

```
├── when delegate call          // First: delegation check
│  └── it should revert
└── when no delegate call
   ├── given null               // Second: existence check
   │  └── it should revert
   └── given not null
      ├── when amount zero      // Third: input validation
      │  └── it should revert
      └── when amount not zero
         └── ...                // Finally: business logic
```

### 2. Use Consistent Terminology

Some examples below:

| Concept                | Convention                |
| ---------------------- | ------------------------- |
| Resource doesn't exist | `given null`              |
| Resource exists        | `given not null`          |
| Caller check           | `when caller {role}`      |
| Amount check           | `when amount {condition}` |

Whenever possible, try to use less words and more concise language for the branches.

### 3. Group Related Conditions

```
└── when withdrawal address not zero
   ├── when withdrawal address not owner    // Non-owner cases
   │  ├── when caller sender
   │  ├── when caller unknown
   │  └── when caller recipient
   └── when withdrawal address owner        // Owner cases
      └── ...
```

### 4. Detailed Leaf Nodes for Happy Path

For success cases, enumerate all side effects:

```
└── it should make the withdrawal
   ├── it should reduce the entry balance by the withdrawn amount
   ├── it should reduce the aggregate amount by the withdrawn amount
   ├── it should update the entry state
   ├── it should update the timestamp
   └── it should emit {Transfer}, {Withdraw} and {MetadataUpdate} events
```

Put events in parenthesis: {EventName}.

### 5. Don't Add a Modifier with the Same Name as the Function

A test function should NEVER have a modifier that matches its own name. The function name already encodes the condition —
adding a same-name modifier is redundant.

```solidity
// WRONG: modifier matches the function name
function test_WhenWithdrawAmountNotZero()
    external
    whenWithdrawalAddressNotZero
    whenWithdrawAmountNotZero // <- WRONG: redundant, same as the function name
{ }

// CORRECT:
function test_WhenWithdrawAmountNotZero() external whenWithdrawalAddressNotZero { }
```

### 6. Use proper indentation

Child branch symbols (├/└) must align with the **tail** of parent's `└──` or `├──` (3 spaces, not 4):

```
└── when withdrawal address not zero
   ├── when withdrawal address not owner    ✓ Correct (3 spaces)
   │  └── when caller sender
```

## Running Bulloak

```bash
# Scaffold tests from tree
bulloak scaffold -wf --skip-modifiers --format-descriptions <path/to/file.tree>

# Check all trees in a directory
bulloak check --skip-modifiers tests/**/*.tree
```

## Full Documentation

https://github.com/alexfertel/bulloak/blob/main/README.md

______________________________________________________________________

## Example Invocations

Test this skill with these prompts:

1. **Basic tree**: "Write a BTT tree for a `deposit` function that reverts when amount is zero and succeeds otherwise"
2. **Complex tree**: "Create a tree spec for `withdraw` that checks null stream, caller authorization, and amount
   validation"
3. **Sablier-specific**: "Write a BTT tree for `cancel` in the Lockup protocol with proper stream state checks"
