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
test workspace path="tests/**/*.sol":
    forge test --root {{ workspace }} \
        --match-path "{{ path }}"

[group("test")]
test-fork workspace: (test workspace "tests/fork/**/*.sol")

[group("test")]
test-integration workspace: (test workspace "tests/integration/**/*.sol")

[group("test")]
test-invariant workspace: (test workspace "tests/invariant/**/*.sol")

[group("test")]
test-unit workspace: (test workspace "tests/unit/**/*.sol")

[group("test")]
test-bulloak workspace:
    bulloak check --tree-path "{{ workspace }}/tests/**/*.tree"

[group("test")]
test-coverage workspace:
    forge coverage --root {{ workspace }} \
        --ir-minimum \
        --match-path "tests/{fork,integration,unit}/**/*.sol" \
        --report lcov

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
