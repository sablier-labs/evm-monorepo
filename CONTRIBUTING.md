# Contributing

Feel free to dive in! [Open](https://github.com/sablier-labs/evm-monorepo/issues/new) an issue, [start](https://github.com/sablier-labs/evm-monorepo/discussions/new/choose) a discussion or submit a PR. For
any informal concerns or feedback, please join our [Discord server](https://discord.gg/bSwRCwWRsT).

Contributions are welcome by anyone interested in writing more tests, improving readability, optimizing for gas
efficiency, or extending the protocol via new features.

## Prerequisites

- [Node.js](https://nodejs.org) (v20+)
- [Just](https://github.com/casey/just) (command runner)
- [Bun](https://bun.sh) (package manager)
- [Ni](https://github.com/antfu-collective/ni) (package manager resolver)
- [Foundry](https://github.com/foundry-rs/foundry) (EVM development framework)
- [Rust](https://rust-lang.org/tools/install) (Rust compiler)
- [Bulloak](https://bulloak.dev) (CLI for checking tests)
- [uv](https://github.com/astral-sh/uv) (tool manager for MDFormat)
- [MDFormat](https://mdformat.readthedocs.io) (Markdown formatter; requires Python 3.13+ and install via `just setup`)

In addition, familiarity with [Solidity](https://soliditylang.org) is requisite.

## Set Up

Clone this repository:

```shell
git clone git@github.com:sablier-labs/evm-monorepo.git && cd evm-monorepo
```

To install the root dependencies:

```shell
bun install
```

Create your root `.env` from `.env.example`:

```shell
cp .env.example .env
```

The setup script installs dependencies in all packages as well as create symlinks for `.env`.

Next, to build all contracts:

```shell
just build-all
```

To build a specific protocol:

```shell
just airdrops::build
just flow::build
just lockup::build
just bob::build
```

Switch to the `staging` branch, where all development work should be done:

```shell
git switch staging
```

Now you can start making changes.

To see a list of all available scripts, run this command:

```shell
just --list
```

## Pull Requests

When making a pull request, ensure that:

- The base development branch is `staging`.
- All tests pass.
- Concrete tests are generated using Bulloak and the Branching Tree Technique (BTT).
  - You can learn more about this on the [Bulloak website](https://bulloak.dev).
  - If you modify a test tree, use this command to generate the corresponding test contract that complies with BTT:
    `bulloak scaffold -wf /path/to/file.tree`
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

- `ROUTEMESH_API_KEY`: sign up on [Routemesh](https://routeme.sh/)

## Integration with VSCode

The following VSCode extensions are not required but are recommended for a better development experience:

- [even-better-toml](https://marketplace.visualstudio.com/items?itemName=tamasfe.even-better-toml)
- [hardhat-solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity)
- [prettier-vscode](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [vscode-solidity-inspector](https://marketplace.visualstudio.com/items?itemName=PraneshASP.vscode-solidity-inspector)
