# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[0.6.0]: https://github.com/PaulRBerg/prb-test/compare/v0.5.7...v0.6.0
[0.5.7]: https://github.com/PaulRBerg/prb-test/compare/v0.5.6...v0.5.7
[0.5.6]: https://github.com/PaulRBerg/prb-test/compare/v0.5.5...v0.5.6
[0.5.5]: https://github.com/PaulRBerg/prb-test/compare/v0.5.4...v0.5.5
[0.5.4]: https://github.com/PaulRBerg/prb-test/compare/v0.5.3...v0.5.4
[0.5.3]: https://github.com/PaulRBerg/prb-test/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/PaulRBerg/prb-test/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/PaulRBerg/prb-test/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/PaulRBerg/prb-test/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/PaulRBerg/prb-test/compare/v0.3.1...v0.4.0
[0.3.1]: https://github.com/PaulRBerg/prb-test/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/PaulRBerg/prb-test/compare/v0.2.1...v0.3.0
[0.2.1]: https://github.com/PaulRBerg/prb-test/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/PaulRBerg/prb-test/compare/v0.1.3...v0.2.0
[0.1.3]: https://github.com/PaulRBerg/prb-test/compare/v0.1.2...v0.1.3
[0.1.2]: https://github.com/PaulRBerg/prb-test/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/PaulRBerg/prb-test/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/PaulRBerg/prb-test/releases/tag/v0.1.0

## [0.6.0] - 2023-05-28

### Changed

- Rename `HEVM_ADDRESS` to `VM_ADDRESS` (@PaulRBerg)

### Added

- Sync `Vm` with forge-std (@PaulRBerg)

## [0.5.7] - 2023-05-05

### Added

- Add breakpoint cheatcodes ([#27](https://github.com/PaulRBerg/prb-test/pull/27)) (@PaulRBerg)
- Add and sync filesystem cheatcodes ([#28](https://github.com/PaulRBerg/prb-test/pull/28)) (@PaulRBerg)

## [0.5.6] - 2023-04-29

### Added

- Add new `expectCall` overloads ([#26](https://github.com/PaulRBerg/prb-test/pull/26)) (@andreivladbrg)

## [0.5.5] - 2023-04-18

### Added

- Add gas metering cheatcodes (@PaulRBerg)

## [0.5.4] - 2023-04-11

### Changed

- Update Node.js dependencies (@PaulRBerg)

### Added

- Sync `Vm` with forge-std (@PaulRBerg)

## [0.5.3] - 2023-03-18

### Added

- Add `MIN_INT256` constant (@PaulRBerg)
- Name `emitter` argument in `expectEmit` variant (@PaulRBerg)

### Fixed

- Fix typos in NatSpec comments (@PaulRBerg)

## [0.5.2] - 2023-03-17

### Added

- Add ASCII art (@PaulRBerg)

## [0.5.1] - 2023-03-10

### Added

- Add simple `expectEmit` variants ([#22](https://github.com/PaulRBerg/prb-test/pull/22)) (@PaulRBerg)

## [0.5.0] - 2023-03-01

### Changed

- Format contracts with `forge fmt` (@PaulRBerg)
- Improve documentation (@PaulRBerg)
- Name the global import of `Helpers.sol` (@PaulRBerg)
- Rename "Expected/Actual" to "Left/Right" in assertion logs (@PaulRBerg)

### Added

- Add new `expectCall` variants (@PaulRBerg)

## [0.4.0] - 2023-02-14

### Changed

- Improve documentation (@PaulRBerg)
- Name return argument in `addr` cheatcode (@PaulRBerg)
- Upgrade Node.js dependencies (@PaulRBerg)

### Added

- Add named alternatives to `contains` and `eq` (@PaulRBerg)
- Add `parseJson` cheatcodes with type coercion (@PaulRBerg)
- Sync `Vm` with forge-std (@PaulRBerg)

## [0.3.1] - 2022-12-12

### Changed

- Improve argument names in `Vm` (@PaulRBerg)

## [0.3.0] - 2022-12-06

### Added

- Add `envOr` cheatcodes (@PaulRBerg)
- Add `fsMetadata` cheatcode (@PaulRBerg)

### Fixed

- Make `accesses` non-view (@PaulRBerg)
- Make `getRecordedLogs` non-view (@PaulRBerg)

## [0.2.1] - 2022-12-04

### Changed

- Fix Prettier formatting issues (@PaulRBerg)

## [0.2.0] - 2022-12-04

### Changed

- Improve wording in CHANGELOG (@PaulRBerg)
- Name arguments in `Vm` interface functions (@PaulRBerg)
- Sync `Vm` with forge-std (@PaulRBerg)
- Set cheatcode mutability/ visibility (@PaulRBerg)
- Split `Vm` in `Vm` and `VmSafe` interfaces (@PaulRBerg)

### Added

- Add `allowCheatcodes` cheatcode (@PaulRBerg)
- Add `broadcast` and `startBroadcast` private key overloads (@PaulRBerg)
- Add `deriveKey` and `rememberKey` cheatcodes (@PaulRBerg)
- Add `difficulty` cheatcode (@PaulRBerg)
- Add fork-related cheatcodes (@PaulRBerg)
- Add `getDeployedCode` (@PaulRBerg)
- Add parsing cheatcodes (@PaulRBerg)
- Add `parseJson` helper functions in `Vm` (@PaulRBerg)
- Add `projectRoot` cheatcode (@PaulRBerg)
- Add `transact` cheatcode (@PaulRBerg)
- Add emitter in `Log` struct (@PaulRBerg)

## [0.1.3] - 2022-10-29

### Changed

- Fix typos in README (@jordaniza, @PaulRBerg)
- Improve usage guides in README (@PaulRBerg)
- Make `IS_TEST` virtual (@PaulRBerg)
- Remove superfluous `bytes20` cast (@PaulRBerg)
- Update fuzzing configuration in `foundry.toml` (@PaulRBerg)

### Added

- Add more information in README (@PaulRBerg)

## [0.1.2] - 2022-07-17

### Fixed

- Switch to global import to fix the overload type checker bug in Solidity v0.8.12
  ([#5](https://github.com/PaulRBerg/prb-test/issues/5)) (@jordaniza, @PaulRBerg)

## [0.1.1] - 2022-07-15

### Fixed

- Add `pinst` as Node.js dev dependency to disable the `postinstall` life cycle script in production (@PaulRBerg)

## [0.1.0] - 2022-07-15

### Added

- First release (@PaulRBerg)
