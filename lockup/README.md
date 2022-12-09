# Sablier V2 Core [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![Styled with Prettier][prettier-badge]][prettier] [![License: LGPL v3][license-badge]][license]

[gha]: https://github.com/sablierhq/v2-core/actions
[gha-badge]: https://github.com/sablierhq/v2-core/actions/workflows/ci.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[prettier]: https://prettier.io
[prettier-badge]: https://img.shields.io/badge/Code_Style-Prettier-ff69b4.svg
[license]: https://www.gnu.org/licenses/lgpl-3.0
[license-badge]: https://img.shields.io/badge/License-LGPL_v3-blue.svg

Core smart contracts of the Sablier V2 cryptoasset streaming protocol. In-depth documentation is available at
[docs.sablier.com](https://docs.sablier.com).

## Install

### Foundry

First, run the install step:

```sh
forge install --no-commit sablierhq/v2-core
```

Then, add the following line to your `remappings.txt` file:

```text
@sablier/v2-core/=lib/v2-core/src/
```

### Hardhat

```sh
yarn add @sablier/v2-core
```

## Contributing

Feel free to dive in! [Open](https://github.com/sablierhq/v2-core/issues/new) an issue,
[start](https://github.com/sablierhq/v2-core/discussions/new) a discussion or submit a PR. For any concerns or feedback,
please join our [Discord server](https://discord.gg/bSwRCwWRsT).

### Pre Requisites

You will need the following software on your machine:

- [Git](https://git-scm.com/downloads)
- [Foundry](https://github.com/foundry-rs/foundry)
- [Node.Js](https://nodejs.org/en/download/)
- [Yarn](https://yarnpkg.com/)

In addition, familiarity with [Solidity](https://soliditylang.org/) is requisite.

### Set Up

Clone this repository including submodules:

```sh
$ git clone --recurse-submodules -j8 git@github.com:sablierhq/v2-core.git
```

Then, inside the project's directory, run this to install the Node.js dependencies:

```sh
$ yarn install
```

Now you can start making changes.

### Syntax Highlighting

You will need the following VSCode extensions:

- [vscode-solidity](https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity)
- [vscode-tree-language](https://marketplace.visualstudio.com/items?itemName=CTC.vscode-tree-extension)

## Tests

Tests are organized in two categories:

1. Unit - simple tests that check the behavior of a single function on a local development EMV.
2. Integration - complex tests that run against a fork of Ethereum Mainnet.

You can run all the tests by using this command:

```sh
forge test
```

By default, only unit tests run. To run all tests, including integration tests, you can use the `--match-path` flag and
pass the path to the `test` directory:

```sh
forge test --match-path ./test/integration
```

To filter tests by name, you can use the `--match-test` flag. Here's an example for the `create` function tests:

```sh
forge test --match-test testCreate
```

You can also filter the tests by test contract name with the `--match-contract` flag. Here's an example for the `create`
function test contract:

```sh
forge test --match-contract Create__Test
```

## Commands

Here's a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Format

Format the contracts with Prettier:

```sh
$ yarn prettier
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ yarn lint
```

### Test

Run the tests:

```sh
$ forge test
```

### Other

There are many other commands available in Foundry. Check out the [Foundry Book](https://book.getfoundry.sh/)!

## Security

For security concerns, please email [security@sablier.com](mailto:security@sablier.com). This repository is subject to
the Sablier bug bounty program, per the terms defined [here](https://docs.sablier.com/).

## License

[LPGL v3.0](./LICENSE.md) © Sablier Labs Ltd
