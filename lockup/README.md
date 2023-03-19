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

Sablier is a smart contract protocol that enables trustless streaming of ERC-20 assets. In the context of Sablier,
streaming means the ability to make payments by the second.

The protocol features a type of stream called a lockup stream, in which the sender locks up a specified amount of ERC-20
assets in a contract. Subsequently, the contract progressively allocates these assets to the designated recipient, who
can access them as they become available. The streaming rate is influenced by various factors, including the start and
end times, as well as the total amount of assets locked up.

## Install

### Foundry

First, run the install step:

```shell
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
src/=src/
```

### Hardhat

Sablier V2 Core is available as a Node.js package:

```shell
pnpm add @sablier/v2-core
```

## Usage

This is just a glimpse of Sablier V2 Core. For more guides and examples, see the
[documentation](https://docs.sablier.com).

```solidity
import { ISablierV2LockupLinear } from "@sablier/v2-core/interfaces/ISablierV2LockupLinear.sol";

contract MyContract {
  ISablierV2LockupLinear sablier;

  function buildSomethingWithSablier() external {
    // ...
  }
}
```

## Security

Please refer to the [SECURITY](./SECURITY.md) policy for any security-related concerns. This repository is subject to a
bug bounty program per the terms outlined in the aforementioned policy.

## Licensing

The primary license for Sablier V2 Core is the Business Source License 1.1 (`BUSL-1.1`), see
[`LICENSE.md`](./LICENSE.md). However, some files are dual-licensed under `GPL-3.0-or-later`:

- All files in `src/interfaces/` and `src/types` may also be licensed under `GPL-3.0-or-later` (as indicated in their
  SPDX headers), see [`LICENSE-GPL.md`](./GPL-LICENSE.md).
- Several files in `src/abstracts/` and `src/libraries/` may also be licensed under `GPL-3.0-or-later` (as indicated in
  their SPDX headers), see [`LICENSE-GPL.md`](./GPL-LICENSE.md).

### Other Exceptions

- All files in `test/` remain unlicensed (as indicated in their SPDX headers).
