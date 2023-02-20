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

Sablier is a cryptoasset streaming protocol that enables trustless streaming of ERC-20 assets. Currently, the protocol
offers a single type of stream, known as a lockup stream, in which the stream creator locks up a specified amount of
ERC-20 assets in the contract. Subsequently, the recipient of the stream can withdraw the assets gradually over time.
The streaming rate is determined by several factors, including the start time, end time, and total amount of assets
locked up. With Sablier, users can enjoy hassle-free, secure, and transparent streaming of their cryptoassets without
the need for intermediaries.

## Install

### Foundry

First, run the install step:

```sh
forge install sablierhq/v2-core
```

Then, add the following remapping:

```text
@sablier/v2-core/=lib/v2-core/src/
```

### Hardhat

Sablier V2 Core is available as an npm package:

```sh
yarn add @sablier/v2-core
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
