# Sablier V2 Core [![Foundry](https://img.shields.io/badge/maintained%20with-foundry-FFDB1C.svg)](https://getfoundry.sh/) [![Styled with Prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg)](https://prettier.io) [![Commitizen Friendly](https://img.shields.io/badge/commitizen-friendly-brightgreen.svg)](http://commitizen.github.io/cz-cli/)

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

## Commands

### Bindings

Generate Rust bindings:

```sh
$ forge bind
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

There are many other cool commands available in Foundry. Check out the [Foundry Book](https://book.getfoundry.sh/)!

## Security

For security concerns, please email [security@sablier.finance](mailto:security@sablier.finance). This repository is subject to the Sablier bug bounty program, per the terms defined [here](https://docs.sablier.finance/).

## License

[LGPL v3](./LICENSE.md) © Mainframe Group Inc.
