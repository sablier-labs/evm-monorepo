# Tests

Tests are organized into three categories:

1. Unit: simple tests that check the behavior of individual functions against a local EVM.
2. Integration: similar to the unit tests but with more complex scenarios that involve multiple contracts.
3. Invariant: conditional expressions that must always hold true.
4. Fork: complex tests that run against an Ethereum Mainnet fork, which ensure that the protocol works with deployed
   ERC-20 assets.

## Running

You can run all tests with this command:

```shell
forge test
```

By default, the tests are not run against the optimized version of the contracts (i.e. the version that gets deployed to
the blockchain). To do this, use the following command:

```shell
pnpm test:optimized
```

## Filtering

To selectively filter tests by name, use the `--match-test` flag (or its shorthand `--mt`). For instance, to execute
only the tests for the `createWithRange` function, run the following command:

```shell
forge test --match-test test_CreateWithRange
```

Additionally, you can filter tests by contract name with the `--match-contract` flag (shorthand `--mc`). The following
example demonstrates how to test the contract containing all tests for the `createWithRange` function:

```shell
forge test --match-contract CreateWithRange
```

## State Trees

You may notice that some test files are accompanied by a corresponding `.tree` file. The goal with this is to structure
the tests within a tree in which the parent nodes represent specific state conditions that govern the smart contract's
behavior, while the leaves signify the conditions being tested.

To replicate the tree in Solidity, we use modifiers following the naming pattern `when<Condition>`.

## Sharing

The tests have a complex inheritance structure because of the significant shared logic between the
`SablierV2LockupLinear` and `SablierV2LockupDynamic` contracts; namely, that both of these contracts inherit from the
`SablierV2Base` and `SablierV2Lockup` abstracts.

To minimize redundancy, we created the following test contracts:

- `Lockup_Integration_Shared_Test`
- `Dynamic_Integration_Shared_Test`
- `Linear_Integration_Shared_Test`

These contracts are then used in the tests corresponding to `SablierV2LockupLinear` and `SablierV2LockupDynamic`.

Pro tip: to visualize the inheritance tree using UML diagrams, install the
[Solidity Visual Developer](https://marketplace.visualstudio.com/items?itemName=tintinweb.solidity-visual-auditor)
extension for VSCode.
