# Changelog

All notable changes to this project will be documented in this file. The format is based on
[Common Changelog](https://common-changelog.org/).

## [1.1.0] - 2026-03-14

### Changed

- Rename `DisableCustomFeeUSD` event to `UpdateCustomFeeUSD` ([#1369](https://github.com/sablier-labs/lockup/pull/1369))
- Drop support for Blast, CoreDAO and SEI chains

### Added

- Add `SafeOracle` library for safe Chainlink oracle price fetching ([#1413](https://github.com/sablier-labs/lockup/pull/1413))
- Add `SafeTokenSymbol` library for safe ERC-20 token symbol retrieval (moved from Lockup's `NFTDescriptor`) ([#1424](https://github.com/sablier-labs/lockup/pull/1424))
- Add `ATTESTOR_MANAGER_ROLE` constant in `RoleAdminable` ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Add attestor management functions: `setAttestor`, `setAttestorForCampaign` ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Add `lowerMinFeeUSDForCampaign` function for campaign fee management ([#1371](https://github.com/sablier-labs/lockup/pull/1371))
- Add `withdrawERC20Token` function for admin ERC-20 token recovery ([#1404](https://github.com/sablier-labs/lockup/pull/1404))
- Add `VERSION` constant to `SablierComptroller` ([#1402](https://github.com/sablier-labs/lockup/pull/1402))
- Add Bob protocol fee support ([#1421](https://github.com/sablier-labs/lockup/pull/1421))

## [1.0.2] - 2025-11-10

### Added

- Support for Monad network

## [1.0.1] - 2025-10-22

### Changed

- Fix the test fork ethereum helper function ([#68](https://github.com/sablier-labs/evm-utils/pull/68))

### Added

- Add more functions in `ChainId` library ([#67](https://github.com/sablier-labs/evm-utils/pull/67))

## [1.0.0] - 2025-09-25

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

[1.0.0]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.0
[1.0.1]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.1
[1.0.2]: https://github.com/sablier-labs/evm-utils/releases/tag/v1.0.2
[1.1.0]: https://github.com/sablier-labs/evm-utils/compare/v1.0.2...v1.1.0
