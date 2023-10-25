# PRBTest [![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/PaulRBerg/prb-test/actions
[gha-badge]: https://github.com/PaulRBerg/prb-test/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/PaulRBerg/prb-test
[codecov-badge]: https://codecov.io/gh/PaulRBerg/prb-test/branch/main/graph/badge.svg?token=T46OSU33QB
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

PRBTest is a modern collection of testing assertions and logging utilities for Solidity, and is meant to be a drop-in
replacement for DSTest.

- Feature-packed: assertions for equalities, inequalities, approximate equalities, numerical comparisons, and more
- Type-rich: every assertion has overloads for `address`, `bytes`, `bytes32`, `int256`, `string` and `uint256`
- Versioned releases so that you don't accidentally pull the latest version and break your test suites
- Meant to be used with Foundry, but can also be used with Hardhat
- Complementary to Forge Std
- Designed for Solidity >=0.8.0
- Thoroughly tested

## Install

### Foundry

First, run the install step:

```sh
forge install --no-commit PaulRBerg/prb-test@v0
```

Your `.gitmodules` file should now contain the following entry:

```toml
[submodule "lib/prb-test"]
  branch = "v0"
  path = "lib/prb-test"
  url = "https://github.com/PaulRBerg/prb-test"
```

Finally, add this to your `remappings.txt` file:

```text
@prb/test/=lib/prb-test/src/
```

### Node.js

```sh
pnpm add @prb/test
# or
npm install @prb/test
```

### Template

If you're starting a project from scratch, the easiest way to install PRBTest is to use my [Foundry
template][my-foundry-template], since it comes pre-configured with PRBTest.

## Usage

Once installed, all you need to do is import `PRBTest` and inherit from it in your test contract. `PRBTest` comes with a
pre-instantiated [cheatcodes](https://book.getfoundry.sh/cheatcodes/) environment accessible via the `vm` property. It
also has support for logs.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { PRBTest } from "@prb/test/PRBTest.sol";

contract MyTest is PRBTest {
  function testExample() external {
    vm.warp(block.timestamp + 100);
    emit Log("Hello World");
    assertTrue(true);
  }
}
```

### Assertions

All assertions have overloads with an additional `err` argument, so that you can pass custom error messages.

| Name             | Argument Types                                                                           |
| ---------------- | ---------------------------------------------------------------------------------------- |
| `assertTrue`     | `bool`                                                                                   |
| `assertFalse`    | `bool`                                                                                   |
| `assertEq`       | `address`, `bytes`, `bytes32`, `int256`, `string`, `uint256` and their array equivalents |
| `assertNotEq`    | `address`, `bytes`, `bytes32`, `int256`, `string`, `uint256` and their array equivalents |
| `assertAlmostEq` | `int256` and `uint256`                                                                   |
| `assertGt`       | `int256` and `uint256`                                                                   |
| `assertGte`      | `int256` and `uint256`                                                                   |
| `assertLt`       | `int256` and `uint256`                                                                   |
| `assertLte`      | `int256` and `uint256`                                                                   |
| `assertContains` | `address[]`, `bytes32[]`, `int256[]`, `string[]`, and `uint256[]`                        |

### Forge Std

PRBTest can be used alongside all testing utilities from [forge-std][forge-std], except for their [Test][forge-std-test]
contract.

Here's an example for how to use PRBTest with `StdCheats` and `stdError`:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { stdError } from "forge-std/Test.sol";

contract MyTest is PRBTest, StdCheats {
  function testArithmeticOverflow() external {
    uint256 a = type(uint256).max;
    uint256 b = 1;
    vm.expectRevert(stdError.arithmeticError);
    a + b;
  }
}
```

## Why Choose PRBTest Over DSTest?

[DSTest][ds-test] is great. I have used it for a while, and I like it a lot. But, with time, I slowly came to realize
that there's a lot of room for improvement.

### 1. Missing Features and Tests

DSTest is incomplete. Some commonly needed assertions, like equality assertions for arrays, `assertEq(bool,bool)` and
`assertNotEq`, are missing from DSTest. PRBTest fills these gaps, and then some.

Also, the DSTest testing assertions are not themselves tested. Whereas the PRBTest testing assertions are tested, and in
fact they are quite thoroughly tested. All other things being equal, this should give you more confidence that your
tests do what you intend them to do.

### 2. No Release Versioning

DSTest doesn't version its releases, which makes it difficult to future-proof consumer repos. It's quite easy to
accidentally update your git submodules and thus break your test suites. For
[some users](https://github.com/dapphub/ds-test/issues/32), this is a real pain.

PRBTest is versioned via tags and branches and all changes are tracked in a [CHANGELOG](./CHANGELOG.md) file. I maintain
redundant branches for each release because git submodules
[don't support tags](https://stackoverflow.com/q/1777854/3873510).

I will strive to follow the [semver](https://semver.org/) versioning scheme, though I won't do this before the v1.0
release, and it might not always be feasible.

### 3. Path Dependence

As one of the maintainers of DSTest said [here](https://github.com/dapphub/ds-test/pull/21#issuecomment-903668033),
updating DSTest is painful to orchestrate. The reasons for this are twofold:

1. Every DappTools project uses it as a git submodule.
2. DSTest releases have not been versioned.

So any significant change in DSTest might wreak havoc downstream.

This issue has led to a "balkanization" of DSTest forks and extensions. See, for instance, Solmate's
[DSTestPlus][ds-test-plus] and Forge Std's [Test][forge-std-test]. Also see the discussions in this
[PR](https://github.com/foundry-rs/forge-std/pull/38), in which the PR author ended up making the PR against `forge-std`
rather than `ds-test` because he feared that his PR won't be merged.

### 4. Lack of Backward Compatibility with Node.js

It is my firm conviction that Foundry is the future of Ethereum smart contract development. Solidity code is best tested
in Solidity itself.

But, due to various historical reasons, the Ethereum ecosystem has for a long time relied upon JavaScript for testing
smart contracts. Refactoring a code base from Hardhat or Truffle to Foundry takes time, and it may not always be
possible to do it in one fell swoop. Thus, to ensure backward compatibility, PRBTest is available as a Node.js package
in the npm package registry.

For more details about this, see this discussion [here](https://github.com/dapphub/ds-test/issues/35).

## Contributing

Feel free to dive in! [Open](https://github.com/paulrberb/prb-test/issues/new) an issue,
[start](https://github.com/paulrberb/prb-test/discussions/new) a discussion or submit a PR.

### Pre Requisites

You will need the following software on your machine:

- [Git](https://git-scm.com/downloads)
- [Foundry](https://github.com/foundry-rs/foundry)
- [Node.Js](https://nodejs.org/en/download/)
- [Pnpm](https://pnpm.io)

In addition, familiarity with [Solidity](https://soliditylang.org/) is requisite.

### Set Up

Clone this repository including submodules:

```sh
$ git clone --recurse-submodules -j8 git@github.com:PaulRBerg/prb-test.git
```

Then, inside the project's directory, run this to install the Node.js dependencies:

```sh
$ pnpm install
```

Now you can start making changes.

### Syntax Highlighting

You will need the following VSCode extensions:

- [hardhat-solidity](https://marketplace.visualstudio.com/items?itemName=NomicFoundation.hardhat-solidity)

## Acknowledgements

These contracts were inspired by or directly modified from the following sources:

- [dapphub/ds-test](https://github.com/dapphub/ds-test/)
- [foundry-rs/forge-std](https://github.com/foundry-rs/forge-std/)

## License

This project is licensed under MIT.

<!-- Links -->

[ds-test]: https://github.com/dapphub/ds-test
[ds-test-plus]:
  https://github.com/Rari-Capital/solmate/blob/03e425421b24c4f75e4a3209b019b367847b7708/src/test/utils/DSTestPlus.sol
[forge-std]: https://github.com/foundry-rs/forge-std
[forge-std-test]: https://github.com/foundry-rs/forge-std/blob/c19dfd2f2a88a461216b0dd1f4961e1a85dcad46/src/Test.sol
[my-foundry-template]: https://github.com/paulrberg/foundry-template
