# Commands

This is a list of the most frequently needed commands.

## Build

Build the contracts using the default profile:

```sh
$ forge build
```

## Build Optimized

Build the contracts using the optimized profile:

```sh
$ pnpm build:optimized
```

This will compile the contracts with the [`--via-ir`](./Tests.md#via-ir) flag enabled.

## Build SMT

Build the contracts with the [SMTChecker](https://docs.soliditylang.org/en/v0.8.18/smtchecker.html) enabled, while
ignoring any warnings due to the use of assembly blocks:

```sh
$ pnpm build:smt
```

This will attempt to formally prove the correctness of the contracts by trying to break invariants (e.g. by finding
failing `assert` statements).

## Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

## Compile

Compile the contracts:

```sh
$ forge build
```

## Format

Format the code:

```sh
$ forge fmt
```

## Gas Report

Get a gas report:

```sh
$ pnpm gas:report
```

## Gas Report Optimized

Get a gas report for the optimized version of the contracts:

```sh
$ pnpm gas:report:optimized
```

## Gas Snapshot

Take a gas snapshot:

```sh
$ pnpm gas:snapshot
```

## Gas Snapshot Optimized

Take a gas snapshot against the optimized version of the contracts:

```sh
$ pnpm gas:snapshot:optimized
```

## Lint

Lint the entire code base (Solidity + other files):

```sh
$ pnpm lint
```

## Lint Sol

Ling the contracts:

```sh
$ pnpm lint:sol
```

## Test

Run the tests:

```sh
$ pnpm test
```

## Test Optimized

Run the tests against the optimized version of the contracts:

```sh
$ pnpm test:optimized
```

## Other

There are many other commands available in Foundry. Check out the [Foundry Book](https://book.getfoundry.sh/)!
