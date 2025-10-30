# See https://github.com/sablier-labs/devkit/just/evm.just
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

# Clean build artifacts in a specific package
@clean package:
    just {{ package }}/clean

# Clean build artifacts in all packages
@clean-all:
    just for-each clean
    rm -rf cache

# Clear node_modules in each package
@clean-modules package:
    just {{ package }}/clean-modules

# Clear node_modules in all packages
@clean-modules-all:
    just for-each clean-modules
    rm -rf node_modules

# Install dependencies in a specific package
install package:
    cd {{ package }} && ni

# Install dependencies in all packages
install-all:
    for dir in airdrops flow lockup utils; do (cd $dir && ni); done

# ---------------------------------------------------------------------------- #
#                                    LINTING                                   #
# ---------------------------------------------------------------------------- #

# Run full check on a specific package
full-check package:
    just {{ package }}/full-check

# Run full check on all packages
full-check-all:
    just for-each full-check

# Run full write on a specific package
full-write package:
    just {{ package }}/full-write

# Run full write on all packages
full-write-all:
    just for-each full-write

# ---------------------------------------------------------------------------- #
#                                    FOUNDRY                                   #
# ---------------------------------------------------------------------------- #

# Build a specific package
[group("foundry")]
build package:
    just {{ package }}/build

# Build all packages
[group("foundry")]
build-all:
    just for-each build

# Build a specific package with optimized profile
[group("foundry")]
build-optimized package *args:
    just {{ package }}/build-optimized {{ args }}

# Build all packages with optimized profile
[group("foundry")]
build-optimized-all:
    just for-each build-optimized

# Run coverage for a specific package
[group("foundry")]
coverage package:
    just {{ package }}/coverage

# Run coverage for all packages
[group("foundry")]
coverage-all:
    just for-each coverage

# Run tests for a specific package
[group("foundry")]
test package *args:
    just {{ package }}/test {{ args }}

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

# Run tests with lite profile for a specific package
[group("foundry")]
test-lite package *args:
    just {{ package }}/test-lite {{ args }}

# Run tests with lite profile for all packages
[group("foundry")]
test-lite-all:
    just for-each test-lite

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
