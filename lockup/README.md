# Sablier Lockup [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Discord][discord-badge]][discord] [![Twitter][twitter-badge]][twitter]

[gha]: https://github.com/sablier-labs/lockup/actions
[gha-badge]: https://github.com/sablier-labs/lockup/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/sablier-labs/lockup
[codecov-badge]: https://codecov.io/gh/sablier-labs/lockup/branch/main/graph/badge.svg
[discord]: https://discord.gg/bSwRCwWRsT
[discord-badge]: https://img.shields.io/discord/659709894315868191
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[twitter-badge]: https://img.shields.io/twitter/follow/Sablier
[twitter]: https://x.com/Sablier

In-depth documentation is available at [docs.sablier.com](https://docs.sablier.com).

## Background

Sablier Lockup is a token distribution protocol that enables onchain vesting and airdrops. Our flagship model is the
linear stream, which distributes tokens on a continuous, by-the-second basis.

The way it works is that the sender of a payment stream first deposits a specific amount of ERC-20 tokens in a contract.
Then, the contract progressively allocates the funds to the recipient, who can access them as they become available over
time. The payment rate is influenced by various factors, including the start and end times, as well as the total amount
of tokens deposited.

## Install

### Node.js

This is the recommended approach.

Install Lockup using your favorite package manager, e.g., with Bun:

```shell
bun add @sablier/lockup
```

### Git Submodules

This installation method is not recommended, but it is available for those who prefer it.

Install the submodule using Forge:

```shell
forge install sablier-labs/lockup
```

Then, install the project's dependencies:

```shell
forge install sablier-labs/evm-utils@v1.0.0 OpenZeppelin/openzeppelin-contracts@v5.3.0 PaulRBerg/prb-math@v4.1.0
```

### Branching Tree Technique

You may notice that some test files are accompanied by `.tree` files. This is because we are using Branching Tree
Technique and [Bulloak](https://bulloak.dev/).

## Usage

This is just a glimpse of Sablier Lockup. For more guides and examples, see the
[documentation](https://docs.sablier.com).

```solidity
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";

contract MyContract {
  ISablierLockup lockup;

  function buildSomethingWithSablier() external {
    // ...
  }
}
```

## Architecture

Lockup uses a singleton-style architecture, where all streams are managed in the `SablierLockup` contract. That is,
Sablier does not deploy a new contract for each distribution model or stream. It bundles all streams into a single
contract, which is more gas-efficient and easier to maintain.

For more information, see the [Technical Overview](https://docs.sablier.com/reference/overview) in our docs, as well as
these [diagrams](https://docs.sablier.com/reference/lockup/diagrams).

## Deployments

The list of all deployment addresses can be found [here](https://docs.sablier.com/guides/lockup/deployments). For
guidance on the deployment scripts, see the [Deployments wiki](https://github.com/sablier-labs/lockup/wiki/Deployments).

## Security

The codebase has undergone rigorous audits by leading security experts from Cantina, as well as independent auditors.
For a comprehensive list of all audits conducted, please click [here](https://github.com/sablier-labs/audits).

For any security-related concerns, please refer to the [SECURITY](./SECURITY.md) policy. This repository is subject to a
bug bounty program per the terms outlined in the aforementioned policy.

## Contributing

Feel free to dive in! [Open](https://github.com/sablier-labs/lockup/issues/new) an issue,
[start](https://github.com/sablier-labs/lockup/discussions/new) a discussion or submit a PR. For any informal concerns
or feedback, please join our [Discord server](https://discord.gg/bSwRCwWRsT).

For guidance on how to create PRs, see the [CONTRIBUTING](./CONTRIBUTING.md) guide.

## License

See [LICENSE.md](./LICENSE.md).
