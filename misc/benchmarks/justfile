# See https://github.com/sablier-labs/devkit/blob/main/just/evm.just
# Run just --list to see all available commands
import "./node_modules/@sablier/devkit/just/evm.just"

default:
  @just --list

# ---------------------------------------------------------------------------- #
#                                    RECIPES                                   #
# ---------------------------------------------------------------------------- #

full-write: solhint-write fmt-write prettier-write format-numbers

format-numbers:
  na ./scripts/format-numbers.js
  na prettier --write "results/**/*.md"


# ---------------------------------------------------------------------------- #
#                                   BENCHMARK                                  #
# ---------------------------------------------------------------------------- #

# Benchmark both Flow and Lockup.
[group("benchmark")]
benchmark-all:
  just benchmark flow
  just benchmark lockup

# Benchmark a specific protocol.
[group("benchmark")]
benchmark *args:
  FOUNDRY_PROFILE={{ args }} forge test --show-progress -vv
  just format-numbers
