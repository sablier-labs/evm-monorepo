# Run just --list to see all available commands
import "./node_modules/@sablier/devkit/just/settings.just"

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
setup: create-symlinks install-all install-mdformat

# Install mdformat with plugins
@install-mdformat:
    uv tool install mdformat \
        --with mdformat-frontmatter \
        --with mdformat-gfm

# Clean .DS_Store files
clean:
    nlx del-cli ".DS_Store"

# ---------------------------------------------------------------------------- #
#                                 ALL PACKAGES                                 #
# ---------------------------------------------------------------------------- #

# Build all packages
[group("all")]
@build-all:
    just for-each build
alias ba := build-all

# Build all packages with optimized profile
[group("all")]
@build-optimized-all:
    just for-each build-optimized

# Clean build artifacts in all packages
[group("all")]
@clean-all:
    just for-each clean
    rm -rf cache

# Clear node_modules in all packages
[group("all")]
@clean-modules-all:
    rm -rf */node_modules
    rm -rf node_modules

# Run coverage for all packages
[group("all")]
@coverage-all:
    just for-each coverage

# Deploy all contracts for all packages
[group("all")]
@deploy-all *args:
    just for-each deploy {{ args }}

# Deploy all contracts for all packages without deterministic addresses
[group("all")]
@deploy-non-deterministic-all *args:
    just for-each deploy-non-deterministic {{ args }}

# Run full check on all packages
[group("all")]
@full-check-all:
    just for-each full-check
alias fca := full-check-all

# Run full write on all packages
[group("all")]
@full-write-all:
    just for-each full-write
alias fwa := full-write-all

# Install dependencies in all packages
[group("all")]
@install-all:
    just for-each install
    bun install

# Run all tests
[group("all")]
@test-all:
    just for-each test
alias ta := test-all

# Run bulloak tests for all packages
[group("all")]
@test-bulloak-all:
    just for-each test-bulloak

# Run tests with lite profile for all packages
[group("all")]
@test-lite-all:
    just for-each test-lite

# Run tests with optimized profile for all packages
[group("all")]
@test-optimized-all:
    just for-each test-optimized

# ---------------------------------------------------------------------------- #
#                                PRIVATE SCRIPTS                               #
# ---------------------------------------------------------------------------- #

# Helper to run recipe in each package
[private]
[script("bash")]
for-each recipe *args:
    set -euo pipefail
    for dir in {{ PACKAGES }}; do
        just "$dir::{{ recipe }}" {{ args }}
    done

# Create .env and .prettierignore symlinks in all packages
[private]
[script("bash")]
create-symlinks:
    set -euo pipefail

    # Create root .env if it doesn't exist
    [ -f .env ] || touch .env

    # Create symlinks in each package
    for dir in {{ PACKAGES }}; do
        # Create .env symlink
        [ -L "$dir/.env" ] || ln -sf ../.env "$dir/.env"
        # Create .prettierignore symlink
        [ -L "$dir/.prettierignore" ] || ln -sf ../.prettierignore "$dir/.prettierignore"
    done
    # Create symlinks in misc
    [ -L "misc/.env" ] || ln -sf ../.env "misc/.env"
    [ -L "misc/.prettierignore" ] || ln -sf ../.prettierignore "misc/.prettierignore"
