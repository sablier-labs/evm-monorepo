# Changelog

All notable changes to this project will be documented in this file. The format is based on
[Common Changelog](https://common-changelog.org/).

[v1.0.0-beta.1]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.0-beta.1
[v1.0.0-beta.2]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.0-beta.2
[v1.0.0-beta.3]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.0-beta.3

## [v1.0.0-beta.3] - 2025-09-10

### Changed

- Return `vm.getBlockTimestamp()` in `getBlockTimestamp()`

## [v1.0.0-beta.2] - 2025-09-02

### Changed

- Bump forge-std to v1.10.0

### Added

- Add Comptroller address on Sepolia

### Removed

- Support for Taiko.

## [v1.0.0-beta.1] - 2025-07-28

### Added

- Add `SablierComptroller` for managing fees across Sablier EVM protocols.
- Add support for UUPS upgradeability for `SablierComptroller`.
- Add `Comptrollerable` to provide a setter and getter for the Sablier Comptroller.
- Add `Adminable` to provide admin functionality with ownership transfer.
- Add `Batch` to provide support for batching of functions.
- Add `NoDelegateCall` to provide support for preventing delegate calls.
- Add `RoleAdminable` to provide role-based access control mechanisms.
- Add base contracts for testing Sablier EVM protocols.
- Add mock contracts used across Sablier EVM protocols.
