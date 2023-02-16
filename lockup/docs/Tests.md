# Tests

Tests are organized into four categories:

1. Unit - simple tests that check the behavior of a single function against a local EVM.
2. Fuzz - similar to the unit tests, but with randomized inputs.
3. Invariant - condition expressions that should always hold true.
4. End-to-end - complex tests that run against a fork of Ethereum Mainnet, which ensure that the protocol works with
   deployed ERC-20 assets.

## Running

You can run all tests by using this command:

```sh
forge test
```

By default, the test are not run against the optimized version of the contracts. To do this, you can use this command:

```sh
yarn test:optimized
```

## Filtering

To filter tests by name, you can use the `--match-test` flag (shorthand `--mt`). Here's an example for how to run only
the unit tests for the `createWithRange` function:

```sh
yarn test --match-test test_CreateWithRange
```

You can also filter the tests by the test contract name with the `--match-contract` flag (shorthand `--mc`). Here's an
example for the test contract that contains all the tests for the `createWithRange` function:

```sh
yarn test --match-contract CreateWithRange_Linear_Unit_Test
```

## Sharing

You will notice that the tests have an inheritance structure. This is because there is a lot of common logic between the
`SablierV2LockupLinear` and the `SablierV2LockupPro` contracts, specifically that they both inherit from the
`SablierV2Config` and the `SablierV2Lockup` abstract contracts.

We wrote the `Lockup_Shared_Test`, `Linear_Shared_Test`, and `Pro_Shared_Test` contracts to avoid duplicating testing
logic, and we inherited them in the test contracts for `SablierV2LockupLinear` and the `SablierV2LockupPro` contracts.
