# Sablier Solidity Utils [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Discord][discord-badge]][discord]

[gha]: https://github.com/sablier-labs/v2-core/actions
[gha-badge]: https://github.com/sablier-labs/v2-core/actions/workflows/ci.yml/badge.svg
[discord]: https://discord.gg/bSwRCwWRsT
[discord-badge]: https://img.shields.io/discord/659709894315868191
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

This repository contains a collection of utility smart contracts used across all Solidity projects. The list of projects
using these contracts includes:

- [Sablier Airdrops](https://github.com/sablier-labs/airdrops/)
- [Sablier Flow](https://github.com/sablier-labs/flow/)
- [Sablier Lockup](https://github.com/sablier-labs/lockup/)

In-depth documentation is available at [docs.sablier.com](https://docs.sablier.com).

## Install

### Node.js

This is the recommended approach.

Install using your favorite package manager, e.g., with Bun:

```shell
bun add @sablier/solidity-utils
```

Then, if you are using Foundry, you need to add these to your `remappings.txt` file:

```text
@sablier/solidity-utils/=node_modules/@sablier/solidity-utils/
```

### Git Submodules

This installation method is not recommended, but it is available for those who prefer it.

First, install the submodule using Forge:

```shell
forge install --no-commit sablier-labs/solidity-utils
```

Second, if you are using Foundry, you need to add these to your `remappings.txt` file:

```text
@sablier/solidity-utils/=lib/solidity-utils/
```

## Usage

```solidity
import { Adminable } from "@sablier/solidity-utils/src/Adminable.sol";
import { Batch } from "@sablier/solidity-utils/src/Batch.sol";
import { NoDelegateCall } from "@sablier/solidity-utils/src/NoDelegateCall.sol";
import { SablierFees } from "@sablier/solidity-utils/src/SablierFees.sol";

contract MyContract is Adminable, Batch, NoDelegateCall, SablierFees {
    constructor(address initialAdmin) SablierFees(initialAdmin) { }

    // Use the `noDelegateCall` modifier to prevent delegate calls.
    function foo() public noDelegateCall { }

    // Use the `onlyAdmin` modifier to restrict access to the admin.
    function editFee(uint256 newFee) public onlyAdmin { }
}
```
