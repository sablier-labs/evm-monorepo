# Sablier EVM Monorepo [![GitHub Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Discord][discord-badge]][discord] [![Twitter][twitter-badge]][twitter]

Monorepo for Sablier's EVM smart contracts. In-depth documentation is available at
[docs.sablier.com](https://docs.sablier.com).

> [!NOTE]
> This repository previously contained only the [Lockup](./lockup) protocol. It has since been expanded into a monorepo
> hosting all of Sablier's EVM smart contracts. Legacy version tags (`v1.0` through `v3.0.1`) refer to Lockup releases
> and have been aliased as `lockup@v1.0` through `lockup@v3.0.1` for clarity.

## Packages

| Package                  | Description                                           | Docs                                                        |
| ------------------------ | ----------------------------------------------------- | ----------------------------------------------------------- |
| [`airdrops`](./airdrops) | Merkle-based token distribution with optional vesting | [Airdrops Docs](https://docs.sablier.com/concepts/airdrops) |
| [`bob`](./bob)           | Price-gated vaults with optional yield adapters       | [Bob Docs](https://docs.sablier.com/concepts/bob/overview)  |
| [`flow`](./flow)         | Open-ended token streaming with no fixed end time     | [Flow Docs](https://docs.sablier.com/concepts/flow)         |
| [`lockup`](./lockup)     | Fixed-term vesting and token distribution             | [Lockup Docs](https://docs.sablier.com/concepts/lockup)     |
| [`utils`](./utils)       | Shared utilities, base contracts, and comptroller     | [Utils README](./utils/README.md)                           |

Each package has its own README with protocol-specific details, installation instructions, and usage examples.

## Security

The codebase has undergone rigorous audits by leading security experts from Cantina, as well as independent auditors.
For a comprehensive list of all audits conducted, please click [here](https://github.com/sablier-labs/audits).

For any security-related concerns, please refer to the [SECURITY](./SECURITY.md) policy. This repository is subject to a
bug bounty program per the terms outlined in the aforementioned policy.

## Contributing

Feel free to dive in! [Open](https://github.com/sablier-labs/evm-monorepo/issues/new) an issue,
[start](https://github.com/sablier-labs/evm-monorepo/discussions/new/choose) a discussion or submit a PR. For any informal
concerns or feedback, please join our [Discord server](https://discord.gg/bSwRCwWRsT).

For full guidance, see the [CONTRIBUTING](./CONTRIBUTING.md) guide.

## License

See [LICENSE.md](./LICENSE.md).

[codecov]: https://codecov.io/gh/sablier-labs/evm-monorepo
[codecov-badge]: https://codecov.io/gh/sablier-labs/evm-monorepo/branch/main/graph/badge.svg
[discord]: https://discord.gg/bSwRCwWRsT
[discord-badge]: https://img.shields.io/discord/659709894315868191
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[gha]: https://github.com/sablier-labs/evm-monorepo/actions
[gha-badge]: https://github.com/sablier-labs/evm-monorepo/actions/workflows/ci-module.yml/badge.svg
[twitter]: https://x.com/Sablier
[twitter-badge]: https://img.shields.io/twitter/follow/Sablier
