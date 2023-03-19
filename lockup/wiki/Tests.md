# Tests

Tests are organized into four categories:

1. Unit: simple tests that check the behavior of individual functions against a local EVM.
2. Fuzz: similar to unit tests, but incorporating randomized inputs to assess robustness.
3. Invariant: conditional expressions that must always hold true.
4. Fork: complex tests that run against an Ethereum Mainnet fork, which ensure that the protocol works with deployed
   ERC-20 assets.

## Running

You can run all tests with this command:

```shell
forge test
```

By default, the tests are not run against the optimized version of the contracts. To do this, use the following command:

```shell
pnpm test:optimized
```

## Filtering

To selectively run tests by name, use the `--match-test` flag (or its shorthand `--mt`). For instance, to execute only
the unit tests for the `createWithRange` function, run the following command:

```shell
pnpm test --match-test test_CreateWithRange
```

Additionally, you can filter tests by contract name with the `--match-contract` flag (shorthand `--mc`). The following
example demonstrates how to test the contract containing all tests for the `createWithRange` function:

```shell
pnpm test --match-contract CreateWithRange_Linear_Unit_Test
```

## State Trees

You may notice that every unit test contract is accompanied by a corresponding `.tree` file. The goal with this is to
structure the tests within a tree in which the parent nodes represent specific state conditions that govern the smart
contract's behavior, while the leaves signify the conditions being tested.

To replicate the tree in Solidity, we use modifiers following the naming pattern `when<Condition>`.

## Sharing

The tests exhibit a complex inheritance structure because of the significant shared logic between the
`SablierV2LockupLinear` and `SablierV2LockupDynamic` contracts; namely, that both inherit from `SablierV2Base` and
`SablierV2Lockup`.

To prevent duplicating test logic, we created the `Lockup_Shared_Test`, `Linear_Shared_Test`, and `Dynamic_Shared_Test`
contracts and inherited them in the test contracts associated with `SablierV2LockupLinear` and `SablierV2LockupDynamic`.
