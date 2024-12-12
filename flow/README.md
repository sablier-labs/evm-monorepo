# Sablier Flow [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Discord][discord-badge]][discord]

[gha]: https://github.com/sablier-labs/flow/actions
[gha-badge]: https://github.com/sablier-labs/flow/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/sablier-labs/flow
[codecov-badge]: https://codecov.io/gh/sablier-labs/flow/branch/main/graph/badge.svg
[discord]: https://discord.gg/bSwRCwWRsT
[discord-badge]: https://dcbadge.vercel.app/api/server/bSwRCwWRsT?style=flat
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

In-depth documentation is available at [docs.sablier.com](https://docs.sablier.com).

## Background

Sablier Flow is a debt tracking protocol that tracks tokens owed between two parties, enabling open-ended token
streaming. A Flow stream is characterized by its rate per second (rps). The relationship between the amount owed and
time elapsed is linear is be defined as:

```math
\text{amount owed} = rps * \text{elapsed time}
```

Sablier Flow can be used in several areas of everyday finance, such as payroll, subscriptions, grant distributions,
insurance premiums, loans interest, token ESOPs etc. If you are looking for vesting and airdrops, please refer to our
[Lockup](https://github.com/sablier-labs/v2-core/) protocol.

## Features

1. **Open-ended:** A stream can be created with no specific end time. It runs indefinitely until it is paused or voided.
2. **Top-ups:** No upfront deposit requirements. A stream can be funded with any amount, at any time, by anyone, in full
   or partially.
3. **Pause:** A stream can be paused by the sender and can later be restarted without losing track of previously accrued
   debt.
4. **Void:** A voided stream cannot be restarted anymore. Voiding an insolvent stream forfeits the uncovered debt.
   Either the sender or the recipient can void a stream at any time.
5. **Refund:** Unstreamed amount can be refunded back to the sender at any time.
6. **Withdraw:** A publicly callable function as long as `to` is set to the recipient. A stream's recipient is allowed
   to withdraw funds to any address.

## Install

### Node.js

This is the recommended approach.

Install Flow using your favorite package manager, e.g. with Bun:

```shell
bun add @sablier/flow
```

Then, if you are using Foundry, you need to add these to your `remappings.txt` file:

```text
@sablier/flow/=node_modules/@sablier/flow/
@openzeppelin/contracts/=node_modules/@openzeppelin/contracts/
@prb/math/=node_modules/@prb/math/
```

### Git Submodules

This installation method is not recommended, but it is available for those who prefer it.

Install the submodule using Forge:

```shell
forge install --no-commit sablier-labs/flow
```

Then, install the project's dependencies:

```shell
forge install --no-commit OpenZeppelin/openzeppelin-contracts@v5.0.2 PaulRBerg/prb-math#95f00b2
```

Finally, add these to your `remappings.txt` file:

```text
@sablier/flow/=lib/flow/
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@prb/math/=lib/prb-math/
```

## Usage

This is just a glimpse of Sablier Flow. For more guides and examples, see the [documentation](https://docs.sablier.com)
and the [technical file](./TECHNICAL-DOC.md).

```solidity
import { ISablierFlow } from "@sablier/flow/src/interfaces/ISablierFlow.sol";

contract MyContract {
  ISablierFlow immutable flow;

  function doSomethingWithFlow(uint256 streamId) external {
    uint128 totalDebt = flow.totalDebtOf(streamId);
    // ...
  }
}
```

## Contributing

Feel free to dive in! [Open](https://github.com/sablier-labs/flow/issues/new) an issue,
[start](https://github.com/sablier-labs/flow/discussions/new) a discussion or submit
[a PR](https://github.com/sablier-labs/flow/compare). For any concerns or feedback, please join our
[Discord server](https://discord.gg/bSwRCwWRsT).

Refer to [CONTRIBUTING](./CONTRIBUTING.md) guidelines if you wish to create a PR.

## License

The primary license for Sablier Flow is the Business Source License 1.1 (`BUSL-1.1`), see [`LICENSE.md`](./LICENSE.md).
However, there are exceptions:

- All files in `src/` with the exception of `SablierFlow.sol` are licensed under `GPL-3.0-or-later`. Refer to
  [`LICENSE-GPL.md`](./LICENSE-GPL.md) for preamble.
- All files in `script/` are licensed under `GPL-3.0-or-later`.
- All files in `tests/` are unlicensed (as indicated in their SPDX headers).
