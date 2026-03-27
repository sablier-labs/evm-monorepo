# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

## [2.0.0] - 2026-03-16

### Changed

- **Breaking**: Rename `RoleGranted` event to `GrantRole` ([#1433](https://github.com/sablier-labs/lockup/pull/1433))
- **Breaking**: Merge `DisableCustomFeeUSD` and `SetCustomFeeUSD` events into `UpdateCustomFeeUSD` ([#1369](https://github.com/sablier-labs/lockup/pull/1369))

### Added

- **Breaking**: Add Bob protocol fee support to initialize function of Comptroller ([#1421](https://github.com/sablier-labs/lockup/pull/1421))
  - Add `Bob` to `ISablierComptroller.Protocol` enum ([#1404](https://github.com/sablier-labs/lockup/pull/1404))
- Add `SafeOracle` library ([#1413](https://github.com/sablier-labs/lockup/pull/1413))
- Add `SafeTokenSymbol` library (moved from `lockup` package) ([#1424](https://github.com/sablier-labs/lockup/pull/1424))
- Add `ATTESTOR_MANAGER_ROLE` role to `RoleAdminable` contract ([#1429](https://github.com/sablier-labs/lockup/pull/1429))
- Add `setAttestor` and `setAttestorForCampaign` functions to Comptroller for managing attestor address ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Add `lowerMinFeeUSDForCampaign` function to Comptroller ([#1371](https://github.com/sablier-labs/lockup/pull/1371))
- Add `withdrawERC20Token` function to withdraw ERC20 Tokens from Comptroller ([#1404](https://github.com/sablier-labs/lockup/pull/1404))
- Add versioning to Comptroller ([#1402](https://github.com/sablier-labs/lockup/pull/1402))
- Add `DEFAULT_SABLIER_MULTISIG_ADMIN` address to `BaseScript` ([#1397](https://github.com/sablier-labs/lockup/pull/1397))

### Removed

- Drop support for Blast, CoreDAO and SEI chains from `ChainId` library ([#1391](https://github.com/sablier-labs/lockup/pull/1391), [#1451](https://github.com/sablier-labs/lockup/pull/1451))

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
[1.0.1]: https://github.com/sablier-labs/evm-utils/compare/v1.0.0...v1.0.1
[1.0.2]: https://github.com/sablier-labs/evm-utils/compare/v1.0.1...v1.0.2
[2.0.0]: https://github.com/sablier-labs/evm-utils/compare/v1.0.2...v2.0.0
