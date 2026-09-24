# Sablier EVM Monorepo

Smart contracts for Sablier onchain token distribution protocol.

## Tech Stack

- **Language**: Solidity 0.8.29
- **Framework**: Foundry
- **Package Manager**: Bun
- **Task Runner**: Just
- **Testing**: Foundry with Bulloak (BTT)
- **Linting**: Solhint, Prettier

## Monorepo Structure

```
├── airdrops/   # Merkle-based token distribution
├── bob/        # Price-target vaults with yield adapters + OTC escrow
├── flow/       # Open-ended token streaming
├── lockup/     # Fixed-term vesting and airdrops
├── utils/      # Shared utilities and comptroller
└── misc/       # Examples and gas benchmarks (not published)
```

Each package has its own `AGENTS.md` with protocol-specific context.

### Resolving `@sablier/evm-utils` Imports

- `airdrops/`, `flow/`, `lockup/`: the dependency is `file:../utils` and its `node_modules` files symlink into `utils/`.
  Read and edit the source in `utils/`, e.g. `@sablier/evm-utils/src/Batch.sol` → `utils/src/Batch.sol`.
- `bob/`: pins a published release. Read `bob/node_modules/@sablier/evm-utils/`; it can differ from `utils/` even when
  the version numbers match.

## Prerequisites

- [Node.js](https://nodejs.org) v20+
- [Just](https://github.com/casey/just) — command runner
- [Bun](https://bun.sh) — package manager (≥1.3)
- [Ni](https://github.com/antfu-collective/ni) — package manager resolver
- [Foundry](https://github.com/foundry-rs/foundry) — EVM development framework
- [Rust](https://rust-lang.org/tools/install) — required by Bulloak
- [Bulloak](https://bulloak.dev) — BTT test scaffolder

## Setup

```shell
git clone git@github.com:sablier-labs/evm-monorepo.git && cd evm-monorepo
bun install                 # installs root + per-package deps, creates symlinks via `just setup`
cp .env.example .env        # populate mnemonic + API keys
just build-all              # build every package
```

## Commands

```shell
just --list                 # list all root recipes
just <pkg>                  # list recipes for a package (airdrops|bob|flow|lockup|utils)
```

`misc/` is not a root module; `cd misc && just --list` to use its recipes.

Common recipes (substitute `<pkg>` for any of the five root modules):

```shell
just build-all              # build every package
just test-all               # run every package's tests
just full-check-all         # lint + format + test across all packages
just <pkg>::build           # build one package
just <pkg>::test            # run tests
just <pkg>::test-lite       # fast tests: lite profile, skips fork tests
just <pkg>::test-optimized  # tests with optimizer profile
just <pkg>::test-bulloak    # verify BTT structure
just <pkg>::coverage        # coverage report
just <pkg>::full-check      # lint + format + test
just <pkg>::full-write      # auto-fix lint + format
just <pkg>::deploy          # deterministic deploy script
```

Generate concrete BTT tests from a tree file:

```shell
bulloak scaffold -wf path/to/file.tree
```

## Code Standards

- Line length: 120 characters
- NatSpec on every public/external function
- Follow existing patterns in each package
- Tests use Branching Tree Technique (BTT) via `.tree` files
- `misc/` (examples, benchmarks) is not part of `build-all` / `test-all` and is unpublished

## Pull Requests

Not accepted. This repository is no longer maintained, and `main` must remain byte-for-byte verifiable against the
[deployed addresses](https://docs.sablier.com/guides/lockup/deployments). Do not open PRs — including comment-only or
docs-only changes — as even trivial edits to source files can alter the compiled bytecode.

## Environment Variables

Local: copy `.env.example` to `.env` and populate the mnemonic + API keys. The `just setup` recipe symlinks the root
`.env` into each package.

CI on forks: add `ROUTEMESH_API_KEY` ([Routemesh](https://routeme.sh/)) to the fork's GitHub Secrets so workflows can
run.
