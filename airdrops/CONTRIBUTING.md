<!-- If you modify this file, remember to update it in the other EVM repos, too! -->

# Contributing

Feel free to dive in! [Open](../../issues/new) an issue, [start](../../discussions/new) a discussion or submit a PR. For
any informal concerns or feedback, please join our [Discord server](https://discord.gg/bSwRCwWRsT).

Contributions to Sablier Airdrops are welcome by anyone interested in writing more tests, improving readability,
optimizing for gas efficiency, or extending the protocol via new features.

## Pre Requisites

You will need the following software on your machine:

- [Git](https://git-scm.com/downloads)
- [Foundry](https://github.com/foundry-rs/foundry)
- [Node.Js](https://nodejs.org/en/download/)
- [Bun](https://bun.sh/)
- [Rust](https://rust-lang.org/tools/install)
- [Bulloak](https://bulloak.dev/)

In addition, familiarity with [Solidity](https://soliditylang.org/) is requisite.

## Set Up

Clone this repository:

```shell
$ git clone git@github.com:sablier-labs/airdrops.git
```

Then, inside the project's directory, run this to install the Node.js dependencies and build the contracts:

```shell
$ bun install
$ bun run build
```

Switch to the `staging` branch, where all development work should be done:

```shell
$ git switch staging
```

Now you can start making changes.

To see a list of all available scripts:

```shell
$ bun run
```

## Pull Requests

When making a pull request, ensure that:

- The base branch is `staging`.
- All tests pass.
  - Fork testing requires environment variables to be set up in the forked repo.
- Code coverage remains the same or greater.
- All new code adheres to the style guide:
  - All lint checks pass.
  - Code is thoroughly commented with NatSpec where relevant.
- If making a change to the contracts:
  - Gas snapshots are provided and demonstrate an improvement (or an acceptable deficit given other improvements).
  - Reference contracts are modified correspondingly if relevant.
  - New tests are included for all new features or code paths.
- A descriptive summary of the PR has been provided.

## Environment Variables

### Local setup

To build locally, follow the [`.env.example`](./.env.example) file to create a `.env` file at the root of the repo and
populate it with the appropriate environment values. You need to provide your mnemonic phrase and a few API keys.

### Deployment

To make CI work in your pull request, ensure that the necessary environment variables are configured in your forked
repository's secrets. Please add the following variable in your GitHub Secrets:

- `API_KEY_INFURA`: sign up on [Infura](https://infura.io/)
- `MAINNET_RPC_URL`: sign up on [Alchemy](https://alchemy.com/)

## Integration with VSCode

The following VSCode extensions are not required but are recommended for a better development experience:

- [even-better-toml](https://marketplace.visualstudio.com/items?itemName=tamasfe.even-better-toml)
- [hardhat-solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity)
- [prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [vscode-solidity-inspector](https://marketplace.visualstudio.com/items?itemName=PraneshASP.vscode-solidity-inspector)
