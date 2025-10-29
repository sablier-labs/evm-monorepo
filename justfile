# See https://github.com/sablier-labs/devkit/blob/main/just/evm.just
# Run just --list to see all available commands
import "./node_modules/@sablier/devkit/just/evm.just"

# ---------------------------------------------------------------------------- #
#                                   ENV VARS                                   #
# ---------------------------------------------------------------------------- #

FOUNDRY_DISABLE_NIGHTLY_WARNING := "true"
# Generate fuzz seed that changes weekly to avoid burning through RPC allowance
FOUNDRY_FUZZ_SEED := `echo $(($EPOCHSECONDS / 604800))`
GLOBS_SOLIDITY := "**/*.sol"

# ---------------------------------------------------------------------------- #
#                                    SCRIPTS                                   #
# ---------------------------------------------------------------------------- #

default:
  @just --list

# Clean build artifacts in all packages
@clean-all:
    just for-each "forge clean --root"

# ---------------------------------------------------------------------------- #
#                                    LINTING                                   #
# ---------------------------------------------------------------------------- #

# Run full check on a specific package
@full-check package:
    just {{ package }}/full-check

# Run full check on all packages
@full-check-all:
    just for-each full-check

# Run full write on a specific package
@full-write package:
    just {{ package }}/full-write

# Run full write on all packages
@full-write-all:
    just for-each full-write

# ---------------------------------------------------------------------------- #
#                                    FOUNDRY                                   #
# ---------------------------------------------------------------------------- #

# Build a specific package
[group("foundry")]
@build package:
    just {{ package }}/build

# Build all packages
[group("foundry")]
@build-all:
    just for-each build

# Build a specific package with optimized profile
[group("foundry")]
@build-optimized package:
    just {{ package }}/build-optimized

# Build all packages with optimized profile
[group("foundry")]
@build-optimized-all:
    just for-each build-optimized

# Run tests for a specific package
[group("foundry")]
test package:
    just {{ package }}/test

# Run all tests
[group("foundry")]
test-all:
    just for-each test

# Run bulloak tests for a specific package
[group("foundry")]
test-bulloak package:
    just {{ package }}/test-bulloak

# Run bulloak tests for all packages
[group("foundry")]
test-bulloak-all:
    just for-each test-bulloak

# Run coverage for a specific package
[group("foundry")]
coverage package:
    just {{ package }}/coverage

# Run coverage for all packages
[group("foundry")]
coverage-all:
    just for-each coverage

# Run tests with optimized profile for a specific package
[group("foundry")]
test-optimized package:
    just {{ package }}/test-optimized

# Run tests with optimized profile for all packages
[group("foundry")]
test-optimized-all:
    just for-each test-optimized

# ---------------------------------------------------------------------------- #
#                                PRIVATE SCRIPTS                               #
# ---------------------------------------------------------------------------- #

# Helper to run recipe in each package
[private]
for-each recipe:
    just airdrops/{{ recipe }}
    just flow/{{ recipe }}
    just lockup/{{ recipe }}
    just utils/{{ recipe }}
