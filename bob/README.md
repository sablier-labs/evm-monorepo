# Sablier Bob [![GitHub Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Twitter][twitter-badge]][twitter]

## Background

This package contains the following protocols:

- [Sablier Bob](./src/SablierBob.sol): Price-gated vaults that unlock deposited tokens based on a target price set. If a
  vault is configured with an adapter, the protocol will automatically stake the tokens and earn yield on behalf of the
  users.

- [Sablier Escrow](./src/SablierEscrow.sol): A peer-to-peer token swap protocol that allows users to swap ERC-20 tokens
  with each other.

## Install

### Node.js

This is the recommended approach.

Install Bob using your favorite package manager, e.g. with Bun:

```shell
bun add @sablier/bob
```

### Git Submodules

This installation method is not recommended, but it is available for those who prefer it.

Install the monorepo and its dependencies using Forge:

```shell
forge install sablier-labs/evm-monorepo@bob@v1.0.1 OpenZeppelin/openzeppelin-contracts@v5.3.0 PaulRBerg/prb-math@v4.1.0 smartcontractkit/chainlink-evm@contracts-v1.4.0
```

Then, add the following remappings in `remappings.txt`:

```text
@chainlink/contracts/=lib/chainlink/contracts-evm/
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@prb/math/=lib/prb-math/
@sablier/evm-utils/=lib/evm-monorepo/utils/
@sablier/bob/=lib/evm-monorepo/bob/
```

## Deployments

The list of all deployment addresses can be found [here](https://docs.sablier.com/guides/bob/deployments).

## Security

The codebase has undergone rigorous audits by leading security experts from Cantina, as well as independent auditors.
For a comprehensive list of all audits conducted, please click [here](https://github.com/sablier-labs/audits).

For any security-related concerns, please refer to the [SECURITY](../SECURITY.md) policy.

## Contributing

This repository is **not accepting pull requests of any kind**, including changes to code comments. Comment-only edits
can change the compiled bytecode, and the source on `main` must remain byte-for-byte verifiable against the
[deployed addresses](https://docs.sablier.com/guides/lockup/deployments). PRs will be closed without review.

For questions or informal feedback, [open an issue](https://github.com/sablier-labs/evm-monorepo/issues/new) or
[start a discussion](https://github.com/sablier-labs/evm-monorepo/discussions/new/choose).

## License

See [LICENSE.md](../LICENSE.md).

[codecov]: https://codecov.io/gh/sablier-labs/evm-monorepo
[codecov-badge]: https://codecov.io/gh/sablier-labs/evm-monorepo/branch/main/graph/badge.svg
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[gha]: https://github.com/sablier-labs/evm-monorepo/actions
[gha-badge]: https://github.com/sablier-labs/evm-monorepo/actions/workflows/ci-bob.yml/badge.svg
[twitter]: https://x.com/Sablier
[twitter-badge]: https://img.shields.io/twitter/follow/Sablier
