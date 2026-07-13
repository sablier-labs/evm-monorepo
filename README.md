# Sablier EVM Monorepo [![GitHub Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Twitter][twitter-badge]][twitter]

> [!IMPORTANT]
>
> **This repository is no longer maintained and is not accepting pull requests** — including changes to code comments.
> Even comment-only edits can alter the compiled bytecode, and the source on `main` must remain byte-for-byte verifiable
> against the [deployed addresses](https://docs.sablier.com/guides/lockup/deployments). PRs of any kind will be closed
> without review.

Monorepo for Sablier's EVM smart contracts. In-depth documentation is available at
[docs.sablier.com](https://docs.sablier.com).

> [!NOTE]
>
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

For any security-related concerns, please refer to the [SECURITY](./SECURITY.md) policy.

## Contributing

This repository is **not accepting pull requests of any kind**, including changes to code comments. Comment-only edits
can change the compiled bytecode, and the source on `main` must remain byte-for-byte verifiable against the
[deployed addresses](https://docs.sablier.com/guides/lockup/deployments). PRs will be closed without review.

For questions or informal feedback, [open an issue](https://github.com/sablier-labs/evm-monorepo/issues/new) or
[start a discussion](https://github.com/sablier-labs/evm-monorepo/discussions/new/choose).

## License

See [LICENSE.md](./LICENSE.md).

[codecov]: https://codecov.io/gh/sablier-labs/evm-monorepo
[codecov-badge]: https://codecov.io/gh/sablier-labs/evm-monorepo/branch/main/graph/badge.svg
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[gha]: https://github.com/sablier-labs/evm-monorepo/actions
[gha-badge]: https://github.com/sablier-labs/evm-monorepo/actions/workflows/ci-module.yml/badge.svg
[twitter]: https://x.com/Sablier
[twitter-badge]: https://img.shields.io/twitter/follow/Sablier
