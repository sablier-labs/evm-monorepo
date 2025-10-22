# Changelog

All notable changes to this project will be documented in this file. The format is based on
[Common Changelog](https://common-changelog.org/).

[v1.0.1]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.1
[v1.0.0]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.0

## [v1.0.1] - 2025-10-22

### Added

- Add more functions in `ChainId` library ([#67](https://github.com/sablier-labs/evm-utils/pull/67))

### Changed

- Fix the test fork ethereum helper function ([#68](https://github.com/sablier-labs/evm-utils/pull/68))

## [v1.0.0] - 2025-09-25

### Added

- Add `SablierComptroller` for managing fees across Sablier EVM protocols
- Add support for UUPS upgradeability for `SablierComptroller`
- Add `Comptrollerable` to provide a setter and getter for the Sablier Comptroller
- Add `Adminable` to provide admin functionality with ownership transfer
- Add `Batch` to provide support for batching of functions
- Add `NoDelegateCall` to provide support for preventing delegate calls
- Add `RoleAdminable` to provide role-based access control mechanisms
- Add base contracts for testing Sablier EVM protocols
- Add mock contracts used across Sablier EVM protocols
