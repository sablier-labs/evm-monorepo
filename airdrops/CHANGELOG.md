# Changelog

All notable changes to this project will be documented in this file. The format is based on
[Common Changelog](https://common-changelog.org/).

## [3.0.0] - 2026-03-14

### Changed

- **Breaking**: Change return type of `totalForgoneAmount()` in `SablierMerkleVCA` from `uint256` to `uint128` ([#1363](https://github.com/sablier-labs/lockup/pull/1363))
- Refactor `SablierMerkleBase` and `SablierMerkleLockup` constructors to accept `ConstructorParams` struct ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Refactor `DataTypes` into separate type files ([#1408](https://github.com/sablier-labs/lockup/pull/1408))
  - `DataTypes` is deprecated and kept only for backward compatibility.

### Added

- **Breaking**: Add `ClaimType` enum to all campaign deployment parameters ([#1405](https://github.com/sablier-labs/lockup/pull/1405))
- **Breaking**: Add `granularity` parameter to `SablierMerkleLL` deployment parameters for configurable unlock step sizes in Linear streams ([#1366](https://github.com/sablier-labs/lockup/pull/1366))
- **Breaking**: Add `enableRedistribution` boolean parameter to `MerkleVCA.ConstructorParams` struct enabling redistribution of forgone tokens ([#1363](https://github.com/sablier-labs/lockup/pull/1363))
- Add `SablierMerkleExecute` campaign contract in which a function is called on a target contract at claim time ([#1393](https://github.com/sablier-labs/lockup/pull/1393))
- Add `claimViaAttestation` function for attestation-based claiming via EIP-712 signatures from a trusted attestor ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Add `sponsor` function to Merkle campaigns ([#1443](https://github.com/sablier-labs/lockup/pull/1443))

### Removed

- **Breaking**: Remove `aggregateAmount` parameter from `createMerkleVCA` function (moved to `MerkleVCA.ConstructorParams` struct parameters) ([#1363](https://github.com/sablier-labs/lockup/pull/1363))

## [2.0.1] - 2025-10-14

### Changed

- Bump package version for NPM release ([#188](https://github.com/sablier-labs/airdrops/pull/188))

## [2.0.0] - 2025-10-08

### Changed

- **Breaking**: Replace single factory with separate factories for each campaign type
  ([#70](https://github.com/sablier-labs/airdrops/pull/70))
- **Breaking**: Store fee as USD value instead of native token value
  ([#68](https://github.com/sablier-labs/airdrops/pull/68))
- **Breaking**: Refactor existing `Claim` events ([#163](https://github.com/sablier-labs/airdrops/pull/163))
- **Breaking**: Rename `STREAM_START_TIME` to `VESTING_START_TIME` in `SablierMerkleLT`
  ([#125](https://github.com/sablier-labs/airdrops/pull/125))
- **Breaking**: Rename `getTranchesWithPercentages` to `tranchesWithPercentages`
- **Breaking**: Rename `getFirstClaimTime()` to `firstClaimTime()`
- **Breaking**: Refactor schedule struct into `immutable` variables in `SablierMerkleLL`
  ([#125](https://github.com/sablier-labs/airdrops/pull/125))

### Added

- Add comptroller via `@sablier/evm-utils` dependency ([#162](https://github.com/sablier-labs/airdrops/pull/162))
- Add `SablierMerkleVCA` contract ([#58](https://github.com/sablier-labs/airdrops/pull/58))
- Add `EIP-712` and `EIP-1271` signature support for claiming airdrops
  ([#160](https://github.com/sablier-labs/airdrops/pull/160))
- Claim airdrops to a third-party address ([#152](https://github.com/sablier-labs/airdrops/pull/152))
- Add campaign start time parameter ([#157](https://github.com/sablier-labs/airdrops/pull/157))
- Add new `Claim` events ([#163](https://github.com/sablier-labs/airdrops/pull/163))
- Add function to get stream IDs associated with airdrop claims
  ([#72](https://github.com/sablier-labs/airdrops/pull/72))
- Transfer tokens directly if claimed after vesting end time ([#77](https://github.com/sablier-labs/airdrops/pull/77))

### Removed

- **Breaking**: Remove `collectFees()` from campaign contracts (moved to factory)

## [1.3.0] - 2025-01-29

<!-- prettier-ignore -->

> [!NOTE]
> Versioning begins at 1.3.0 as this repository is the successor of [V2 Periphery](https://github.com/sablier-labs/v2-periphery). For previous changes, please refer to the [V2 Periphery Changelog](https://github.com/sablier-labs/v2-periphery/blob/main/CHANGELOG.md).

### Changed

- Replace `createWithDurations` with `createWithTimestamps` in both `MerkleLL` and `MerkleLT` claims
  ([#1024](https://github.com/sablier-labs/v2-core/pull/1024), [#28](https://github.com/sablier-labs/airdrops/pull/28))

### Added

- Introduce `SablierMerkleInstant` contract to support campaigns for instantly unlocked airdrops
  ([#999](https://github.com/sablier-labs/v2-core/pull/999))
- Add an option to configure claim fees in the native tokens, managed by the protocol admin. The fee can only be charged
  on the new campaigns, and cannot be changed on campaigns once they are created
  ([#1038](https://github.com/sablier-labs/v2-core/pull/1038),
  [#1040](https://github.com/sablier-labs/v2-core/issues/1040))

### Removed

- Remove `V2` from the contract names and related references ([#994](https://github.com/sablier-labs/v2-core/pull/994))

[1.3.0]: https://github.com/sablier-labs/airdrops/releases/tag/v1.3.0
[2.0.0]: https://github.com/sablier-labs/airdrops/compare/v1.3.0...v2.0.0
[2.0.1]: https://github.com/sablier-labs/airdrops/compare/v2.0.0...v2.0.1
[3.0.0]: https://github.com/sablier-labs/airdrops/compare/v2.0.1...v3.0.0
