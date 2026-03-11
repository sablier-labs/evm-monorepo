# See https://github.com/sablier-labs/devkit/blob/main/just/evm.just
# Run just --list to see all available commands
import "./node_modules/@sablier/devkit/just/evm.just"

# Override constants for this project structure
GLOBS_PRETTIER := "**/*.{md,yml}"
GLOBS_SOLIDITY := "{airdrops,flow,lockup}/**/*.sol"

default:
  @just --list

# Build all contracts (airdrops, flow, lockup)
[group("build")]
build: build-airdrops build-flow build-lockup
alias ba := build

# Build airdrops contracts
[group("build")]
build-airdrops:
  FOUNDRY_PROFILE=airdrops forge build

# Build flow contracts
[group("build")]
build-flow:
  FOUNDRY_PROFILE=flow forge build

# Build lockup contracts
[group("build")]
build-lockup:
  FOUNDRY_PROFILE=lockup forge build

# Test all contracts (airdrops, flow, lockup)
[group("test")]
test: test-airdrops test-flow test-lockup
alias ta := test

# Test airdrops contracts
[group("test")]
test-airdrops:
  FOUNDRY_PROFILE=airdrops forge test

# Test flow contracts
[group("test")]
test-flow:
  FOUNDRY_PROFILE=flow forge test

# Test lockup contracts
[group("test")]
test-lockup:
  FOUNDRY_PROFILE=lockup forge test

# Override formatting and checking commands for project-specific paths
# Run all code checks on airdrops, flow, lockup
[group("format")]
full-check: (solhint-check GLOBS_SOLIDITY) fmt-check (prettier-check GLOBS_PRETTIER)

# Run all code fixes on airdrops, flow, lockup
[group("format")]
full-write: (solhint-write GLOBS_SOLIDITY) fmt-write (prettier-write GLOBS_PRETTIER)

# Check code with Forge formatter for airdrops, flow, lockup
[group("format")]
fmt-check:
  forge fmt --check airdrops/ flow/ lockup/

# Fix code with Forge formatter for airdrops, flow, lockup
[group("format")]
fmt-write:
  forge fmt airdrops/ flow/ lockup/
