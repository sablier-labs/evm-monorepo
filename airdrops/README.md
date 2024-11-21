# Sablier Airdrops [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Discord][discord-badge]][discord]

[gha]: https://github.com/sablier-labs/airdrops/actions
[gha-badge]: https://github.com/sablier-labs/airdrops/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/sablier-labs/airdrops
[codecov-badge]: https://codecov.io/gh/sablier-labs/airdrops/branch/main/graph/badge.svg
[discord]: https://discord.gg/bSwRCwWRsT
[discord-badge]: https://dcbadge.vercel.app/api/server/bSwRCwWRsT?style=flat
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

In-depth documentation is available at [docs.sablier.com](https://docs.sablier.com).

## Introduction

Sablier Airdrops is a collection of smart contracts that allows airdrops of ERC-20 tokens using Merkle trees. It offers
multiple distributions options, including:

1. Instant airdrops: The simplest way to distribute tokens to a list of addresses. Eligible users can claim and receive
   their allocation instantly via a single claim transaction.
2. Vesting airdrops: This is the way to go if you want your users to receive tokens over time through vesting. Upon
   claiming, eligible users will have their tokens streamed through Sablier over a period specified by the campaign
   owner. This distribution option has been referred to as Airstreams in the past.

Sablier Airdrops also offer flexibility in configuring the Airdrop campaigns. For example, you can choose between
whether you want to have vesting to begin at the same time for all user (absolute) or at the time of each claim
(relative).

## Documentation

For guides and technical details, check out the [Sablier documentation](https://docs.sablier.com).

## Getting started

### Install

You can install this repo using either Node.js or Git Submodules.

#### Node.js

This is the recommended approach.

Install this repo using your favorite package manager, e.g., with Bun:

```shell
bun add @sablier/airdrops
```

Then, if you are using Foundry, you need to add these to your `remappings.txt` file:

```text
@sablier/airdrops/=node_modules/@sablier/airdrops/
@openzeppelin/contracts/=node_modules/@openzeppelin/contracts/
@prb/math/=node_modules/@prb/math/
```

#### Git Submodules

This installation method is not recommended, but it is available for those who prefer it.

First, install the submodule using Forge:

```shell
forge install --no-commit sablier-labs/airdrops
```

Second, install the project's dependencies:

```shell
forge install --no-commit OpenZeppelin/openzeppelin-contracts@v5.0.2 PaulRBerg/prb-math@v4.1.0 sablier-labs/lockup@v2.0.0
```

Finally, add these to your `remappings.txt` file:

```text
@sablier/airdrops/=lib/airdrops/
@sablier/lockup/=lib/lockup/src/
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@prb/math/=lib/prb-math/
```

### Branching Tree Technique

You may notice that some test files are accompanied by `.tree` files. This is called the Branching Tree Technique, and
it is explained in depth [here](https://bulloak.dev/).

### Deployments

The list of all deployment addresses can be found [here](https://docs.sablier.com).

## Security

The codebase has undergone rigorous audits by leading security experts from Cantina, as well as independent auditors.
For a comprehensive list of all audits conducted, please click [here](https://github.com/sablier-labs/audits).

For any security-related concerns, please refer to the [SECURITY](./SECURITY.md) policy. This repository is subject to a
bug bounty program per the terms outlined in the aforementioned policy.

## Contributing

Feel free to dive in! [Open](https://github.com/sablier-labs/airdrops/issues/new) an issue,
[start](https://github.com/sablier-labs/airdrops/discussions/new) a discussion or submit a PR. For any informal concerns
or feedback, please join our [Discord server](https://discord.gg/bSwRCwWRsT).

For guidance on how to create PRs, see the [CONTRIBUTING](./CONTRIBUTING.md) guide.

## License

The primary license for Sablier Airdrops is the Business Source License 1.1 (`BUSL-1.1`), see
[`LICENSE.md`](./LICENSE.md). However, there are exceptions:

- All files in `src/interfaces/` and `src/types` are licensed under `GPL-3.0-or-later`, see
  [`LICENSE-GPL.md`](./LICENSE-GPL.md).
- Several files in `src`, `script`, and `tests` are licensed under `GPL-3.0-or-later`, see
  [`LICENSE-GPL.md`](./LICENSE-GPL.md).
- Many files in `tests/` remain unlicensed (as indicated in their SPDX headers).
