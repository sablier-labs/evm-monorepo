# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[2.0.1]: https://github.com/sablier-labs/flow/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/sablier-labs/flow/compare/v1.1.1...v2.0.0
[1.1.1]: https://github.com/sablier-labs/flow/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sablier-labs/flow/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/sablier-labs/flow/releases/tag/v1.0.0

## [2.0.1] - 2025-10-22

### Changed

- Bump `@sablier/evm-utils` to v1.0.1 ([#475](https://github.com/sablier-labs/flow/pull/475/))

### Removed

- Remove `solady` dependency ([#474](https://github.com/sablier-labs/flow/pull/474/))

## [2.0.0] - 2025-10-14

### Changed

- **Breaking:** Replace admin with comptroller ([#451](https://github.com/sablier-labs/flow/pull/451),
  [#454](https://github.com/sablier-labs/flow/pull/454))
- **Breaking**: Adjusting rate per second is no longer allowed with zero value
  ([#392](https://github.com/sablier-labs/flow/pull/392))
- Rename `aggregateBalance` to `aggregateAmount` ([#418](https://github.com/sablier-labs/flow/pull/418))
- Rename `SablierFlowBase` to `SablierFlowState` ([#446](https://github.com/sablier-labs/flow/pull/446))
- Bump Solidity compiler version 0.8.29 ([#403](https://github.com/sablier-labs/flow/pull/403))
- Bump `@openzeppelin/contracts` from 5.0.2 to 5.3.0

### Added

- Add support for creating streams with a start time ([#392](https://github.com/sablier-labs/flow/pull/392))
- Add `PENDING` status ([#392](https://github.com/sablier-labs/flow/pull/392))
- Add token transfer wrapper functionality ([#391](https://github.com/sablier-labs/flow/pull/391))
- Function to calculate minimum fee in wei ([#454](https://github.com/sablier-labs/flow/pull/454))
- Emit creator address in stream creation events ([#456](https://github.com/sablier-labs/flow/pull/456))
- Return refunded amount on `refundMax` function ([#445](https://github.com/sablier-labs/flow/pull/445))
- Add `@sablier/evm-utils` dependency

### Removed

- **Breaking:** Remove the protocol fee in underlying token ([#385](https://github.com/sablier-labs/flow/pull/385))
- **Breaking:** Remove broker fee functionality ([#384](https://github.com/sablier-labs/flow/pull/384))
- **Breaking:** Remove return value from `withdraw` function ([#385](https://github.com/sablier-labs/flow/pull/385))
- Remove `isPaused` getter function ([#440](https://github.com/sablier-labs/flow/pull/440))
- Remove `Adminable` and `Batch` contracts (moved to `@sablier/evm-utils`)

## [1.1.1] - 2025-02-05

### Changed

- Use relative path to import source contracts in test utils files
  ([#383](https://github.com/sablier-labs/flow/pull/383))

## [1.1.0] - 2025-01-29

### Changed

- Refactor the `batch` function to return an array of results if all call succeeds, and bubble up the revert if any call
  fails ([#358](https://github.com/sablier-labs/flow/pull/358))

### Added

- Add `payable` modifier to all the functions ([#348](https://github.com/sablier-labs/flow/pull/348))

## [1.0.0] - 2024-12-07

### Added

- Initial release
