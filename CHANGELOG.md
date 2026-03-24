# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

For detailed per-package changelogs, see each package's `CHANGELOG.md`:

- [airdrops](./airdrops/CHANGELOG.md)
- [bob](./bob/CHANGELOG.md)
- [flow](./flow/CHANGELOG.md)
- [lockup](./lockup/CHANGELOG.md)
- [utils](./utils/CHANGELOG.md)

## March 23, 2026

#### [airdrops@v3.0.1](https://www.npmjs.com/package/@sablier/airdrops/v/3.0.1)

- Bump `lockup` and `utils` package ([#1483](https://github.com/sablier-labs/evm-monorepo/pull/1483))

#### [bob@v1.0.1](https://www.npmjs.com/package/@sablier/bob/v/1.0.1)

- Bump utils package ([#1481](https://github.com/sablier-labs/evm-monorepo/pull/1481))

#### [flow@v3.0.1](https://www.npmjs.com/package/@sablier/flow/v/3.0.1)

- Bump utils package ([#1481](https://github.com/sablier-labs/evm-monorepo/pull/1481))

#### [lockup@v4.0.1](https://www.npmjs.com/package/@sablier/lockup/v/4.0.1)

- Bump utils package ([#1481](https://github.com/sablier-labs/evm-monorepo/pull/1481))

#### [utils@v2.0.1](https://www.npmjs.com/package/@sablier/evm-utils/v/2.0.1)

- Add support for Denergy chain ([#1464](https://github.com/sablier-labs/evm-monorepo/pull/1464))
- Drop support for Mode Sepolia and Sophon ([#1463](https://github.com/sablier-labs/evm-monorepo/pull/1463), [#1467](https://github.com/sablier-labs/evm-monorepo/pull/1467))

## March 16, 2026

#### [airdrops@v3.0.0](https://www.npmjs.com/package/@sablier/airdrops/v/3.0.0)

- **Breaking:** Change return type of `totalForgoneAmount()` in `SablierMerkleVCA` from `uint256` to `uint128`
  ([#1363](https://github.com/sablier-labs/lockup/pull/1363))
- **Breaking:** Add `ClaimType` enum to all campaign deployment parameters
  ([#1405](https://github.com/sablier-labs/lockup/pull/1405))
- **Breaking:** Add `granularity` parameter to `SablierMerkleLL` deployment parameters
  ([#1366](https://github.com/sablier-labs/lockup/pull/1366))
- **Breaking:** Add `enableRedistribution` boolean parameter to `MerkleVCA.ConstructorParams` struct
  ([#1363](https://github.com/sablier-labs/lockup/pull/1363))
- Refactor `SablierMerkleBase` and `SablierMerkleLockup` constructors to accept `ConstructorParams` struct
  ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Refactor `DataTypes` into separate type files
  ([#1408](https://github.com/sablier-labs/lockup/pull/1408))
- **New Contract:** Add `SablierMerkleExecute` campaign contract for calling functions on a target contract at claim time
  ([#1393](https://github.com/sablier-labs/lockup/pull/1393))
- Add `claimViaAttestation` function for attestation-based claiming via EIP-712 signatures
  ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Add `sponsor` function to Merkle campaigns
  ([#1443](https://github.com/sablier-labs/lockup/pull/1443))
- **Breaking:** Remove `aggregateAmount` parameter from `createMerkleVCA` function
  ([#1363](https://github.com/sablier-labs/lockup/pull/1363))

#### [bob@v1.0.0](https://www.npmjs.com/package/@sablier/bob/v/1.0.0)

- Initial release

#### [flow@v3.0.0](https://www.npmjs.com/package/@sablier/flow/v/3.0.0)

- Rename `Helpers` library to `FlowHelpers`
  ([#1370](https://github.com/sablier-labs/lockup/pull/1370))
- Add `transferFromPayable` function
  ([#1384](https://github.com/sablier-labs/lockup/pull/1384))
- **Breaking:** Remove `Recover` event from `recover` function
  ([#1439](https://github.com/sablier-labs/lockup/pull/1439))
- Remove zero surplus check from `recover` function
  ([#1439](https://github.com/sablier-labs/lockup/pull/1439))

#### [lockup@v4.0.0](https://www.npmjs.com/package/@sablier/lockup/v/4.0.0)

- **Breaking:** Add `granularity` parameter to Lockup Linear create functions
  ([#1366](https://github.com/sablier-labs/lockup/pull/1366))
- Rename `Helpers` library to `LockupHelpers`
  ([#1370](https://github.com/sablier-labs/lockup/pull/1370))
- **New Model:** Add Price Gated model to Lockup that unlocks tokens based on a target price of the stream token
  ([#1406](https://github.com/sablier-labs/lockup/pull/1406),
  [#1416](https://github.com/sablier-labs/lockup/pull/1416))
- Add `createWithTimestampsLPG` to `SablierBatchLockup` contract
  ([#1416](https://github.com/sablier-labs/lockup/pull/1416))
- Remove `safeTokenSymbol` and `isAllowedCharacter` functions from `LockupNFTDescriptor` (moved to `@sablier/evm-utils`)
  ([#1424](https://github.com/sablier-labs/lockup/pull/1424))
- Fix: Add zero-check validation for segment count and tranche count in `LockupHelpers`
  ([#1429](https://github.com/sablier-labs/lockup/pull/1429))

#### [utils@v2.0.0](https://www.npmjs.com/package/@sablier/evm-utils/v/2.0.0)

- **Breaking:** Rename `RoleGranted` event to `GrantRole`
  ([#1433](https://github.com/sablier-labs/lockup/pull/1433))
- **Breaking:** Merge `DisableCustomFeeUSD` and `SetCustomFeeUSD` events into `UpdateCustomFeeUSD`
  ([#1369](https://github.com/sablier-labs/lockup/pull/1369))
- **Breaking:** Add Bob protocol fee support to Comptroller initialize function
  ([#1421](https://github.com/sablier-labs/lockup/pull/1421))
- Add `Bob` to `ISablierComptroller.Protocol` enum
  ([#1404](https://github.com/sablier-labs/lockup/pull/1404))
- Add `SafeOracle` library
  ([#1413](https://github.com/sablier-labs/lockup/pull/1413))
- Add `SafeTokenSymbol` library (moved from `lockup` package)
  ([#1424](https://github.com/sablier-labs/lockup/pull/1424))
- Add `ATTESTOR_MANAGER_ROLE` role to `RoleAdminable` contract
  ([#1429](https://github.com/sablier-labs/lockup/pull/1429))
- Add `setAttestor` and `setAttestorForCampaign` functions to Comptroller
  ([#1403](https://github.com/sablier-labs/lockup/pull/1403))
- Add `lowerMinFeeUSDForCampaign` function to Comptroller
  ([#1371](https://github.com/sablier-labs/lockup/pull/1371))
- Add `withdrawERC20Token` function to Comptroller
  ([#1404](https://github.com/sablier-labs/lockup/pull/1404))
- Add versioning to Comptroller
  ([#1402](https://github.com/sablier-labs/lockup/pull/1402))
- Add `DEFAULT_SABLIER_MULTISIG_ADMIN` address to `BaseScript`
  ([#1397](https://github.com/sablier-labs/lockup/pull/1397))
- Drop support for Blast, CoreDAO and SEI chains from `ChainId` library
  ([#1391](https://github.com/sablier-labs/lockup/pull/1391),
  [#1451](https://github.com/sablier-labs/lockup/pull/1451))
