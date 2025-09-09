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

# Build a specific workspace
@build workspace:
    forge build --root {{ workspace }}
alias b := build

# Build all workspaces
@build-all:
    just for-each "forge build --root"

# Check code with Forge formatter
@fmt-check:
    just for-each "forge fmt --check --root"

# Fix code with Forge formatter
@fmt-write:
    just for-each "forge fmt --root"

# ---------------------------------------------------------------------------- #
#                                    TESTS                                     #
# ---------------------------------------------------------------------------- #

[group("test")]
test path="tests/**/*.sol":
    forge test --match-path "{{ path }}"

# ---------------------------------------------------------------------------- #
#                                PRIVATE SCRIPTS                               #
# ---------------------------------------------------------------------------- #

# Helper to run script for all packages
[private]
for-each script:
    {{ script }} airdrops
    {{ script }} flow
    {{ script }} lockup
    {{ script }} utils
