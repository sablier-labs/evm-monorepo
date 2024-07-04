# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[1.2.0]: https://github.com/sablier-labs/v2-core/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/sablier-labs/v2-core/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/sablier-labs/v2-core/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sablier-labs/v2-core/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/sablier-labs/v2-core/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/sablier-labs/v2-core/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/sablier-labs/v2-core/releases/tag/v1.0.0

## [1.2.0] - 2024-07-04

### Changed

- **Breaking:** move common logic into `Lockup` contract ([#784](https://github.com/sablier-labs/v2-core/pull/784),
  [#813](https://github.com/sablier-labs/v2-core/pull/813), [#850](https://github.com/sablier-labs/v2-core/pull/850),
  [#941](https://github.com/sablier-labs/v2-core/pull/941))
- **Breaking:** use a new hook system ([#951](https://github.com/sablier-labs/v2-core/pull/951))
  - Replace `ISablierV2Recipient` with `ISablierLockupRecipient` hook interface
  - Remove `try..catch` block from hook calls
- Allow only supported characters in NFT Descriptor asset symbols
  ([#945](https://github.com/sablier-labs/v2-core/pull/945), [#960](https://github.com/sablier-labs/v2-core/pull/960),
  [#949](https://github.com/sablier-labs/v2-core/pull/949))
- Bump build dependencies ([#806](https://github.com/sablier-labs/v2-core/pull/806),
  [#942](https://github.com/sablier-labs/v2-core/pull/942), [#944](https://github.com/sablier-labs/v2-core/pull/944))
- Change permissions of `withdraw` function to public ([#785](https://github.com/sablier-labs/v2-core/pull/785))
- Disallow zero `startTime` ([#813](https://github.com/sablier-labs/v2-core/pull/813),
  [#852](https://github.com/sablier-labs/v2-core/pull/852))
- Rename create functions `createWithTimestamps` and `createWithDurations` across all lockup contracts
  ([#798](https://github.com/sablier-labs/v2-core/pull/798))
- Switch to Bun ([#775](https://github.com/sablier-labs/v2-core/pull/775))
- Use Solidity v0.8.26 ([#944](https://github.com/sablier-labs/v2-core/pull/944))

### Added

- Add Lockup Tranched contract ([#817](https://github.com/sablier-labs/v2-core/pull/817))
- Add `precompiles` in the NPM release ([#841](https://github.com/sablier-labs/v2-core/pull/841))
- Add return value in `withdrawMax` and `withdrawMaxAndTransfer`
  ([#961](https://github.com/sablier-labs/v2-core/pull/961))

### Removed

- **Breaking:** remove protocol fee ([#839](https://github.com/sablier-labs/v2-core/pull/839))
- Remove flash loan abstract contract ([#779](https://github.com/sablier-labs/v2-core/pull/779))
- Remove `to` from `withdrawMultiple` function ([#785](https://github.com/sablier-labs/v2-core/pull/785))

## [1.1.2] - 2023-12-19

### Changed

- Use Solidity v0.8.23 ([#758](https://github.com/sablier-labs/v2-core/pull/758))

## [1.1.1] - 2023-12-16

### Changed

- Bump package version for NPM release
  ([88db61](https://github.com/sablier-labs/v2-core/tree/88db61bcf193ef9494b31c883ed2c9ad997a1271))

## [1.1.0] - 2023-12-15

### Changed

- **Breaking**: Remove ability to cancel for recipients ([#710](https://github.com/sablier-labs/v2-core/pull/710))
- Move `isWarm` and `isCold` to `SablierV2Lockup` ([#664](https://github.com/sablier-labs/v2-core/pull/664))
- Replace the streamed amount with the deposit amount in the NFT descriptor
  ([#692](https://github.com/sablier-labs/v2-core/pull/692))
- Simplify `renounce` and `withdraw` implementations ([#683](https://github.com/sablier-labs/v2-core/pull/683),
  [#705](https://github.com/sablier-labs/v2-core/pull/705))
- Update import paths to use Node.js dependencies ([#734](https://github.com/sablier-labs/v2-core/pull/734))
- Use Solidity v0.8.21 ([#688](https://github.com/sablier-labs/v2-core/pull/688))

### Added

- Add `ERC-4906` metadata update in `transferFrom` ([#686](https://github.com/sablier-labs/v2-core/pull/686))
- Add `transferable` boolean flag ([#668](https://github.com/sablier-labs/v2-core/pull/668))

### Removed

- Remove `@openzeppelin/contracts` from Node.js peer dependencies
  ([#694](https://github.com/sablier-labs/v2-core/pull/694))

## [1.0.2] - 2023-08-14

### Changed

- Update `@prb/math` import paths to contain `src/` ([#648](https://github.com/sablier-labs/v2-core/pull/648))

## [1.0.1] - 2023-07-13

### Changed

- Optimize use of variables in `tokenURI` ([#617](https://github.com/sablier-labs/v2-core/pull/617))

### Fixed

- Fix data URI scheme in `tokenURI` ([#617](https://github.com/sablier-labs/v2-core/pull/617))

## [1.0.0] - 2023-07-07

### Added

- Initial release
