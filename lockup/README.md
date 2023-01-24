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

### Environment Variables

Some of the features of this repository, such as deployments, require environment variables to be set up.

Follow the [`.env.example`](./.env.example) file to create a `.env` file at the root of the repo and populate it with
the appropriate environment values. You need to provide your mnemonic phrase and a few API keys.

### Syntax Highlighting

You may want to install the following VSCode extensions to get syntax highlighting in VSCode:

- [vscode-solidity](https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity)
- [vscode-tree-language](https://marketplace.visualstudio.com/items?itemName=CTC.vscode-tree-extension)

## Deployments

You can deploy the contracts in this repository in two ways: (i) programmatically with Forge, or (ii) manually using the
GitHub UI.

### Programmatically

To be able to deploy contracts programmatically, you need to have your environment variables correctly set up, as
explained above.

The examples below deploy to the Goerli testnet, but you can pick any other chain defined under the `[rpc_endpoints]`
section in [`foundry.toml`](./foundry.toml).

If you want to deploy to a local development chain, you can spin up an instance of
[Anvil](https://book.getfoundry.sh/anvil).

#### Deploy SablierV2Comptroller

```sh
forge script scripts/DeployComptroller.s.sol \
  --broadcast \
  --rpc-url goerli
```

#### Deploy SablierV2LockupLinear

You should replace the placeholders with the actual arguments you want to pass.

```sh
forge script script/DeployLinear.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,uint256)" \
  COMPTROLLER_ADDRESS
  MAX_FEE
```

#### Deploy SablierV2LockupPro

You should replace the placeholders with the actual arguments you want to pass.

```sh
forge script script/DeployPro.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(address,uint256,uint256)" \
  COMPTROLLER_ADDRESS
  MAX_FEE
  MAX_SEGMENT_COUNT
```

#### Deploy Protocol

```sh
forge script script/DeployProtocol.s.sol \
  --broadcast \
  --rpc-url goerli \
  --sig "run(uint256,uint256)" \
  MAX_FEE
  MAX_SEGMENT_COUNT
```

#### Deploy Test Token

```sh
forge script script/DeployTestToken.s.sol \
  --broadcast \
  --rpc-url goerli
```

#### GitHub UI

Just switch to the [Actions tab](https://github.com/sablierhq/v2-core/actions) and pick one of the workflows from the
left sidebar. Then, provide the required inputs and click on the "Run workflow" button.

Note: write access to the repository is required to deploy using the GitHub UI.

## Via IR

We deploy our contracts with the [`--via-ir`](https://docs.soliditylang.org/en/v0.8.17/ir-breaking-changes.html) flag
enabled.

This means that the contracts are compiled with a lot of powerful optimizations, but the cost is very slow compile
times. Nonetheless, we have to run our tests against this optimized version of the contracts, since this is what end
users will ultimately interact with.

To get the best of both worlds, we have come up with a set-up where on our local machines we build and test the
contracts normally, but in CI we build and test the contracts with IR enabled. This gives us the freedom to develop and
test the contracts rapidly, but also the peace of mind that they work as expected when deployed (tests pass with and
without IR enabled).

## Tests

Tests are organized in two categories:

1. Unit - simple tests that check the behavior of a single function on a local development EMV.
2. Integration - complex tests that run against a fork of Ethereum Mainnet to check that Sablier V2 works with deployed
   ERC-20 tokens.

You can run all tests by using this command:

```sh
forge test
```

By default, only unit tests run. To run all tests, including integration tests, you can use this command:

```sh
yarn test:optimized
```

Alternatively, you could change the value of the `test` configuration option in the [`foundry.toml`](./foundry.toml)
file to `test/integration`.

To filter tests by name, you can use the `--match-test` flag. Here's an example for the `createWithRange` function
tests:

```sh
forge test --match-test testCreateWithRange
```

You can also filter the tests by test contract name with the `--match-contract` flag. Here's an example for the
`createWithRange` function test contracts:

```sh
forge test --match-contract CreateWithRange
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
