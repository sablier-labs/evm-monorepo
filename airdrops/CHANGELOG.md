# Changelog

All notable changes to this project will be documented in this file. The format is based on
[Common Changelog](https://common-changelog.org/).

[2.0.0]: https://github.com/sablier-labs/airdrops/compare/v1.3.0...v2.0.0
[1.3.0]: https://github.com/sablier-labs/airdrops/releases/tag/v1.3.0

## [2.0.0] - 2025-10-08

### Changed

- **BREAKING**: Replace single factory with separate factories for each campaign type
  ([#70](https://github.com/sablier-labs/airdrops/pull/70))
- Rename `STREAM_START_TIME` to `VESTING_START_TIME`
- Rename `defaultFee` to `minimumFee` ([#68](https://github.com/sablier-labs/airdrops/pull/68))
- Rename `getTranchesWithPercentages` to `tranchesWithPercentages`
- Rename `TOTAL_PERCENTAGE` to `TRANCHES_TOTAL_PERCENTAGE`
- Rename `getFirstClaimTime()` to `firstClaimTime()`
- Refactor claim events ([#163](https://github.com/sablier-labs/airdrops/pull/163))

### Added

- Add comptroller via `@sablier/evm-utils` dependency ([#162](https://github.com/sablier-labs/airdrops/pull/162))
- Add `SablierMerkleVCA` contract ([#58](https://github.com/sablier-labs/airdrops/pull/58))
- Add EIP-712 and EIP-1271 signature support for claiming airdrops
  ([#160](https://github.com/sablier-labs/airdrops/pull/160))
- Add ability to claim airdrops to a third-party address ([#152](https://github.com/sablier-labs/airdrops/pull/152))
- Add campaign start time parameter ([#157](https://github.com/sablier-labs/airdrops/pull/157))
- Add function to get stream IDs associated with airdrop claims
  ([#72](https://github.com/sablier-labs/airdrops/pull/72))
- Add direct token transfer when claimed after vesting end time
  ([#77](https://github.com/sablier-labs/airdrops/pull/77))

### Removed

- Remove `collectFees()` from campaign contracts (moved to factory)

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
