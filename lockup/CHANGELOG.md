# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[3.0.1]: https://github.com/sablier-labs/lockup/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/sablier-labs/lockup/compare/v2.0.1...v3.0.0
[2.0.1]: https://github.com/sablier-labs/lockup/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/sablier-labs/lockup/compare/v1.2.0...v2.0.0
[1.2.0]: https://github.com/sablier-labs/lockup/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/sablier-labs/lockup/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/sablier-labs/lockup/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sablier-labs/lockup/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/sablier-labs/lockup/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/sablier-labs/lockup/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/sablier-labs/lockup/releases/tag/v1.0.0

## [3.0.1] - 2025-10-14

### Changed

- Bump package version for NPM release ([#1297](https://github.com/sablier-labs/lockup/pull/1297))

## [3.0.0] - 2025-10-07

### Changed

- **Breaking:** Refactor `SablierLockup` contract into model-specific abstract contracts
  ([#1261](https://github.com/sablier-labs/lockup/pull/1261))
- Refactor `DataTypes` into separate type files ([#1261](https://github.com/sablier-labs/lockup/pull/1261))
  - `DataTypes` is kept for backward compatibility and will be deprecated in the future versions.
- Replace admin with comptroller ([#1260](https://github.com/sablier-labs/lockup/pull/1260),
  [#1268](https://github.com/sablier-labs/lockup/pull/1268))
- Rename `VestingMath` library to `LockupMath`
- Rename `SablierLockupBase` to `SablierLockupState` ([#1247](https://github.com/sablier-labs/lockup/pull/1247))
- Make `cancelMultiple` non-reverting ([#1173](https://github.com/sablier-labs/lockup/pull/1173))
- Rename `aggregateBalance` to `aggregateAmount` ([#1228](https://github.com/sablier-labs/lockup/pull/1228))
- Bump Solidity compiler to 0.8.29 ([#1207](https://github.com/sablier-labs/lockup/pull/1207))
- Bump `@openzeppelin/contracts` from 5.0.2 to 5.3.0

### Added

- ERC20 recovery functionality ([#1182](https://github.com/sablier-labs/lockup/pull/1182))
- Function to calculate minimum fee in wei ([#1270](https://github.com/sablier-labs/lockup/pull/1270))
- `CreateBatchLockup` event in `BatchLockup` ([#1274](https://github.com/sablier-labs/lockup/pull/1274))
- Return refunded amount in `cancel` ([#1173](https://github.com/sablier-labs/lockup/pull/1173))
- Add `@sablier/evm-utils` dependency

### Removed

- **Breaking:** Remove `MAX_COUNT` constant ([#1243](https://github.com/sablier-labs/lockup/pull/1243))
- **Breaking**: Remove broker functionality ([#1166](https://github.com/sablier-labs/lockup/pull/1166))
- Remove `Adminable` and `Batch` contracts (moved to `@sablier/evm-utils`)

## [2.0.1] - 2025-02-05

### Changed

- Use relative path to import source contracts in test utils files
  ([#1169](https://github.com/sablier-labs/lockup/pull/1169))

### Removed

- Remove `DeployOptimized.sol` from npm package ([#1169](https://github.com/sablier-labs/lockup/pull/1169))

## [2.0.0] - 2025-01-28

### Changed

- **Breaking:** merge `SablierV2LockupLinear`, `SablierV2LockupDynamic` and `SablierV2LockupTranched` into a single
  contract called `SablierLockup` ([#1069](https://github.com/sablier-labs/v2-core/pull/1069))
  - Implement two public libraries `VestingMath` and `Helpers`
  - Implement `Model` enum to differentiate between linear, dynamic and tranched streams
- Allow setting the end time of linear streams to a past date
  ([#1015](https://github.com/sablier-labs/v2-core/pull/1015))
- Emit revert errors in `withdrawMultiple` instead of halting execution on failed withdrawals
  ([#1101](https://github.com/sablier-labs/v2-core/pull/1101))
- Allow approved accounts to execute `withdrawMaxAndTranfer` on behalf of recipients
  ([#1054](https://github.com/sablier-labs/v2-core/pull/1054))
- Refactor `asset` to `token` when referring to `ERC20` tokens
  ([#1097](https://github.com/sablier-labs/v2-core/pull/1097))
- Rename this repo to **Lockup** ([#994](https://github.com/sablier-labs/v2-core/pull/994))

### Added

- **Breaking:** introduce new configurations for unlock amounts at start time and cliff time in create Linear functions
  ([#1075](https://github.com/sablier-labs/v2-core/pull/1075))
- Implement a `batch` function to execute multiple functions in a single transaction
  ([#1070](https://github.com/sablier-labs/v2-core/pull/1070),
  [#1126](https://github.com/sablier-labs/v2-core/pull/1126))
- Emit the expected shape name of the stream through create functions
  ([#1094](https://github.com/sablier-labs/v2-core/pull/1094),
  [#1100](https://github.com/sablier-labs/v2-core/pull/1100))
- Implement `renounceMultiple` function to renounce multiple streams in a single transaction
  ([#1091](https://github.com/sablier-labs/v2-core/pull/1091))
- Moved the `SablierBatchLockup` contract from [v2-periphery](https://github.com/sablier-labs/v2-periphery/) to the
  Lockup repository ([#1084](https://github.com/sablier-labs/v2-core/pull/1084))
- Add `payable` modifier to all the functions ([#1093](https://github.com/sablier-labs/v2-core/pull/1093))

### Removed

- No longer support backward compatibility with previous versions of `Lockup` contract in `NFTDescriptor`
  ([#1113](https://github.com/sablier-labs/v2-core/pull/1113))
- Remove `V2` from the contract names and related references ([#994](https://github.com/sablier-labs/v2-core/pull/994))
- Remove `precompiles` from the NPM release ([#1158](https://github.com/sablier-labs/v2-core/pull/1158))

## [1.2.0] - 2024-07-04

### Changed

- **Breaking:** move common logic into `Lockup` contract ([#784](https://github.com/sablier-labs/lockup/pull/784),
  [#813](https://github.com/sablier-labs/lockup/pull/813), [#850](https://github.com/sablier-labs/lockup/pull/850),
  [#941](https://github.com/sablier-labs/lockup/pull/941))
- **Breaking:** use a new hook system ([#951](https://github.com/sablier-labs/lockup/pull/951))
  - Replace `ISablierV2Recipient` with `ISablierLockupRecipient` hook interface
  - Remove `try..catch` block from hook calls
- Allow only supported characters in NFT Descriptor asset symbols
  ([#945](https://github.com/sablier-labs/lockup/pull/945), [#960](https://github.com/sablier-labs/lockup/pull/960),
  [#949](https://github.com/sablier-labs/lockup/pull/949))
- Bump build dependencies ([#806](https://github.com/sablier-labs/lockup/pull/806),
  [#942](https://github.com/sablier-labs/lockup/pull/942), [#944](https://github.com/sablier-labs/lockup/pull/944))
- Change permissions of `withdraw` function to public ([#785](https://github.com/sablier-labs/lockup/pull/785))
- Disallow zero `startTime` ([#813](https://github.com/sablier-labs/lockup/pull/813),
  [#852](https://github.com/sablier-labs/lockup/pull/852))
- Rename create functions `createWithTimestamps` and `createWithDurations` across all lockup contracts
  ([#798](https://github.com/sablier-labs/lockup/pull/798))
- Rename `milestone` to `timestamp` in the `LockupDynamic.Segment` data type
- Switch to Bun ([#775](https://github.com/sablier-labs/lockup/pull/775))
- Use Solidity v0.8.26 ([#944](https://github.com/sablier-labs/lockup/pull/944))

### Added

- Add Lockup Tranched contract ([#817](https://github.com/sablier-labs/lockup/pull/817))
- Add `precompiles` in the NPM release ([#841](https://github.com/sablier-labs/lockup/pull/841))
- Add return value in `withdrawMax` and `withdrawMaxAndTransfer`
  ([#961](https://github.com/sablier-labs/lockup/pull/961))

### Removed

- **Breaking:** remove protocol fee ([#839](https://github.com/sablier-labs/lockup/pull/839))
- Remove flash loan abstract contract ([#779](https://github.com/sablier-labs/lockup/pull/779))
- Remove `to` from `withdrawMultiple` function ([#785](https://github.com/sablier-labs/lockup/pull/785))

## [1.1.2] - 2023-12-19

### Changed

- Use Solidity v0.8.23 ([#758](https://github.com/sablier-labs/lockup/pull/758))

## [1.1.1] - 2023-12-16

### Changed

- Bump package version for NPM release
  ([88db61](https://github.com/sablier-labs/lockup/tree/88db61bcf193ef9494b31c883ed2c9ad997a1271))

## [1.1.0] - 2023-12-15

### Changed

- **Breaking**: Remove ability to cancel for recipients ([#710](https://github.com/sablier-labs/lockup/pull/710))
- Move `isWarm` and `isCold` to `SablierV2Lockup` ([#664](https://github.com/sablier-labs/lockup/pull/664))
- Replace the streamed amount with the deposit amount in the NFT descriptor
  ([#692](https://github.com/sablier-labs/lockup/pull/692))
- Simplify `renounce` and `withdraw` implementations ([#683](https://github.com/sablier-labs/lockup/pull/683),
  [#705](https://github.com/sablier-labs/lockup/pull/705))
- Update import paths to use Node.js dependencies ([#734](https://github.com/sablier-labs/lockup/pull/734))
- Use Solidity v0.8.21 ([#688](https://github.com/sablier-labs/lockup/pull/688))

### Added

- Add `ERC-4906` metadata update in `transferFrom` ([#686](https://github.com/sablier-labs/lockup/pull/686))
- Add `transferable` boolean flag ([#668](https://github.com/sablier-labs/lockup/pull/668))

### Removed

- Remove `@openzeppelin/contracts` from Node.js peer dependencies
  ([#694](https://github.com/sablier-labs/lockup/pull/694))

## [1.0.2] - 2023-08-14

### Changed

- Update `@prb/math` import paths to contain `src/` ([#648](https://github.com/sablier-labs/lockup/pull/648))

## [1.0.1] - 2023-07-13

### Changed

- Optimize use of variables in `tokenURI` ([#617](https://github.com/sablier-labs/lockup/pull/617))

### Fixed

- Fix data URI scheme in `tokenURI` ([#617](https://github.com/sablier-labs/lockup/pull/617))

## [1.0.0] - 2023-07-07

### Added

- Initial release
