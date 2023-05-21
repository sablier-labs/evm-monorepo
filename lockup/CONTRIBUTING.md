# Contributing

Feel free to dive in! [Open](https://github.com/sablier-labs/v2-core/issues/new) an issue,
[start](https://github.com/sablier-labs/v2-core/discussions/new) a discussion or submit a PR. For any informal concerns
or feedback, please join our [Discord server](https://discord.gg/bSwRCwWRsT).

Contributions to Sablier V2 Core are welcome by anyone interested in writing more tests, improving readability,
optimizing for gas efficiency, or extending the protocol via new features.

## Pre Requisites

You will need the following software on your machine:

- [Git](https://git-scm.com/downloads)
- [Foundry](https://github.com/foundry-rs/foundry)
- [Node.Js](https://nodejs.org/en/download/)
- [Pnpm](https://pnpm.io/)

In addition, familiarity with [Solidity](https://soliditylang.org/) is requisite.

## Set Up

Clone this repository including submodules:

```shell
$ git clone --recurse-submodules -j8 git@github.com:sablier-labs/v2-core.git
```

Then, inside the project's directory, run this to install the Node.js dependencies:

```shell
$ pnpm install
```

Now you can start making changes.

## Pull Requests

When making a pull request, ensure that:

- All tests pass.
- Code coverage remains the same or greater.
- All new code adheres to the style guide:
  - All lint checks pass.
  - Code is thoroughly commented with NatSpec where relevant.
- If making a change to the contracts:
  - Gas snapshots are provided and demonstrate an improvement (or an acceptable deficit given other improvements).
  - Reference contracts are modified correspondingly if relevant.
  - New tests are included for all new features or code paths.
- If making a modification to third-party Node.js dependencies, `pnpm audit` passes.
- A descriptive summary of the PR has been provided.

## Environment Variables

Some of the features of this repository, such as deployments, require environment variables to be set up.

Follow the [`.env.example`](./.env.example) file to create a `.env` file at the root of the repo and populate it with
the appropriate environment values. You need to provide your mnemonic phrase and a few API keys.

## Integration with VSCode:

Install the following VSCode extensions:

- [esbenp.prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [hardhat-solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity)
- [vscode-tree-language](https://marketplace.visualstudio.com/items?itemName=CTC.vscode-tree-extension)
