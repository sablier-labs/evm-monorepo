# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

<!-- prettier-ignore -->
> [!NOTE]
> Versioning begins at 1.3.0 as this repository is the successor of [V2 Periphery](https://github.com/sablier-labs/v2-periphery). For previous changes, please refer to the [V2 Periphery Changelog](https://github.com/sablier-labs/v2-periphery/blob/main/CHANGELOG.md).

## 1.3.0 - 2025-01-24

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
