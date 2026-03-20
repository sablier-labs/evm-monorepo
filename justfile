# See https://github.com/sablier-labs/devkit/just/base.just
# Run just --list to see all available commands
import "./node_modules/@sablier/devkit/just/base.just"

# Modules, use like this: just lockup::<recipe>
mod airdrops "airdrops"
mod bob "bob"
mod flow "flow"
mod lockup "lockup"
mod utils "utils"

# ---------------------------------------------------------------------------- #
#                                   ENV VARS                                   #
# ---------------------------------------------------------------------------- #

export FOUNDRY_DISABLE_NIGHTLY_WARNING := "true"
# Generate fuzz seed that changes weekly to avoid burning through RPC allowance
export FOUNDRY_FUZZ_SEED := `echo $(($EPOCHSECONDS / 604800))`

# All monorepo packages
PACKAGES := "airdrops bob flow lockup utils"

# ---------------------------------------------------------------------------- #
#                                    SCRIPTS                                   #
# ---------------------------------------------------------------------------- #

default:
  @just --list

# Setup script
setup: setup-env install-all install-mdformat

# ---------------------------------------------------------------------------- #
#                                 ALL PACKAGES                                 #
# ---------------------------------------------------------------------------- #

# Build all packages
[group("all")]
build-all:
    just for-each build

# Build all packages with optimized profile
[group("all")]
build-optimized-all:
    just for-each build-optimized

# Clean build artifacts in all packages
[group("all")]
clean-all:
    just for-each clean
    rm -rf cache

# Clear node_modules in all packages
[group("all")]
clean-modules-all:
    just for-each clean-modules
    rm -rf node_modules

# Run coverage for all packages
[group("all")]
coverage-all:
    just for-each coverage

# Deploy all contracts for all packages
[group("all")]
deploy-all *args:
    just for-each deploy {{ args }}

# Run full check on all packages
[group("all")]
full-check-all:
    just for-each full-check

# Run full write on all packages
[group("all")]
full-write-all:
    just for-each full-write

# Install dependencies in all packages
[group("all")]
install-all:
    just for-each install

# Run all tests
[group("all")]
test-all:
    just for-each test

# Run bulloak tests for all packages
[group("all")]
test-bulloak-all:
    just for-each test-bulloak

# Run tests with lite profile for all packages
[group("all")]
test-lite-all:
    just for-each test-lite

# Run tests with optimized profile for all packages
[group("all")]
test-optimized-all:
    just for-each test-optimized

# ---------------------------------------------------------------------------- #
#                                PRIVATE SCRIPTS                               #
# ---------------------------------------------------------------------------- #

# Helper to run recipe in each package
[private]
for-each recipe *args:
    #!/usr/bin/env bash
    set -euo pipefail
    for dir in {{ PACKAGES }}; do
        just "$dir::{{ recipe }}" {{ args }}
    done

# Setup .env and .prettierignore symlinks in all packages
[private]
setup-env:
    #!/usr/bin/env bash
    # Create root .env if it doesn't exist
    [ ! -f .env ] && touch .env
    # Create symlinks in each package
    for dir in {{ PACKAGES }}; do
        [ ! -L "$dir/.env" ] && ln -sf ../.env "$dir/.env" || true
        [ ! -L "$dir/.prettierignore" ] && ln -sf ../.prettierignore "$dir/.prettierignore" || true
    done
    # Create symlinks in misc
    [ ! -L "misc/.env" ] && ln -sf ../.env "misc/.env" || true
    [ ! -L "misc/.prettierignore" ] && ln -sf ../.prettierignore "misc/.prettierignore" || true
