# Sablier V2 Core [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![Styled with Prettier][prettier-badge]][prettier] [![License: LGPL v3][license-badge]][license]

[gha]: https://github.com/sablierhq/v2-core/actions
[gha-badge]: https://github.com/sablierhq/v2-core/actions/workflows/integration.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[prettier]: https://prettier.io
[prettier-badge]: https://img.shields.io/badge/Code_Style-Prettier-ff69b4.svg
[license]: https://www.gnu.org/licenses/lgpl-3.0
[license-badge]: https://img.shields.io/badge/License-LGPL_v3-blue.svg

Core smart contracts of the Sablier V2 money streaming protocol. In-depth documentation is available at [docs.sablier.finance](https://docs.sablier.finance).

## Usage

### Foundry

How to import the Sablier V2 smart contracts in a Foundry project:

```sh
forge install --no-commit sablierhq/v2-core
```

### Hardhat

How to import the Sablier V2 smart contracts in a Hardhat project:

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

In addition, familiarity with [Solidity](https://soliditylang.org/) is requisite.

### Set Up

Clone this repository including submodules:

```sh
$ git clone --recurse-submodules -j8 git@github.com:sablierhq/v2-core.git
```

Then, follow the example given in `.env.example` to create a `.env` file with the requisite environment variables.

Now you can start making changes.

### Syntax Highlighting

You will need the following VSCode extensions:

- [vscode-solidity](https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity)
- [vscode-tree-language](https://marketplace.visualstudio.com/items?itemName=CTC.vscode-tree-extension)

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

For security concerns, please email [security@sablier.finance](mailto:security@sablier.finance). This repository is subject to the Sablier bug bounty program, per the terms defined [here](https://docs.sablier.finance/).

## License

[LPGL v3.0](./LICENSE.md) © Sablier Labs Ltd
