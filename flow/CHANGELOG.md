# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Common Changelog](https://common-changelog.org/).

[1.1.1]: https://github.com/sablier-labs/flow/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/sablier-labs/flow/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/sablier-labs/flow/releases/tag/v1.0.0

## [1.1.1] - 2025-02-05

### Changed

- Use relative path to import source contracts in test utils files
  ([#383](https://github.com/sablier-labs/flow/pull/383))

## [1.1.0] - 2025-01-29

### Changed

- Refactor the `batch` function to return an array of results if all call succeeds, and bubble up the revert if any call
  fails ([#358](https://github.com/sablier-labs/flow/pull/358))

### Added

- Add `payable` modifier to all the functions ([#348](https://github.com/sablier-labs/flow/pull/348))

## [1.0.0] - 2024-12-07

### Added

- Initial release
