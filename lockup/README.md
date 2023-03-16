# Sablier V2 Core [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry]

[gha]: https://github.com/sablierhq/v2-core/actions
[gha-badge]: https://github.com/sablierhq/v2-core/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/sablierhq/v2-core
[codecov-badge]: https://codecov.io/gh/sablierhq/v2-core/branch/main/graph/badge.svg?token=ND1LZOUF2G
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

This repository contains the core smart contracts of the Sablier V2 Protocol. For higher-level logic, see the
[sablierhq/v2-periphery](https://github.com/sablierhq/v2-periphery) repository.

In-depth documentation is available at [docs.sablier.com](https://docs.sablier.com).

## Background

Sablier is a smart contract protocol that enables trustless streaming of ERC-20 assets. In this context, streaming means
the ability to make payments by the second.

Currently, the protocol offers a single type of stream, called a lockup stream. In a lockup stream, the stream creator
locks up a specified amount of ERC-20 assets in a contract. The recipient of the stream can then withdraw the assets
gradually over time. The streaming rate is determined by multiple factors, including the start and end times, and the
total amount of assets locked up.

## Install

### Foundry

First, run the install step:

```sh
forge install sablierhq/v2-core
```

Your `.gitmodules` file should now contain the following entry:

```toml
[submodule "lib/v2-core"]
  branch = "main"
  path = "lib/v2-core"
  url = "https://github.com/sablierhq/v2-core"
```

Finally, add this to your `remappings.txt` file:

```text
@sablier/v2-core/=lib/v2-core/src/
```

### Hardhat

Sablier V2 Core is available as an npm package:

```sh
pnpm add @sablier/v2-core
```

## Usage

This is just a glimpse of Sablier V2 Core. For more code snippets, see the [documentation](https://docs.sablier.com).

```solidity
import { ISablierV2LockupLinear } from "@sablier/v2-core/interfaces/ISablierV2LockupLinear.sol";

contract MyContract {
  ISablierV2LockupLinear lockupLinear;

  function doSomethingWithLockupLinear() external {
    // ...
  }
}
```

## Security

For security concerns, please see the [SECURITY](./SECURITY.md) policy. This repository is subject to a bug bounty
program, per the terms defined in the policy.

## Licensing

The primary license for Sablier V2 Core is the Business Source License 1.1 (`BUSL-1.1`), see
[`LICENSE.md`](./LICENSE.md). However, some files are dual-licensed under `GPL-2.0-or-later`:

- All files in `src/interfaces/` and `src/types` may also be licensed under `GPL-2.0-or-later` (as indicated in their
  SPDX headers), see [`LICENSE-GPL.md`](./GPL-LICENSE.md).
- Several files in `src/libraries/` may also be licensed under `GPL-2.0-or-later` (as indicated in their SPDX headers),
  see [`LICENSE-GPL.md`](./GPL-LICENSE.md).

### Other Exceptions

- All files in `test/` remain unlicensed (as indicated in their SPDX headers).
