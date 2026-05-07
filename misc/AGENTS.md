# Sablier Examples and Benchmarks

@../AGENTS.md

Unpublished package containing example integrations and gas benchmarks.

> **Disclaimer**: Examples are NOT audited and are for demonstration only. Do not use in production.

## Package Structure

```
benchmarks/
├── results/                # Markdown tables checked into the repo (also published on docs.sablier.com)
├── scripts/                # Number formatting helpers
└── src/{flow,lockup}/      # Solidity benchmark contracts (per Foundry profile)
examples/
├── airdrops/               # Airdrops integration examples
├── flow/                   # Flow integration examples
└── lockup/                 # Lockup integration examples
```

## Foundry Profiles

Examples and benchmarks each have dedicated Foundry profiles in `foundry.toml`:

- `examples-airdrops`, `examples-flow`, `examples-lockup`
- `benchmarks-flow`, `benchmarks-lockup`

## Commands

### Examples

```shell
just build-examples              # build all example contracts
just build-examples-airdrops     # build airdrops examples only
just build-examples-flow         # build flow examples only
just build-examples-lockup       # build lockup examples only
just test-examples               # run all example tests
just test-examples-airdrops      # tests for airdrops examples
just test-examples-flow          # tests for flow examples
just test-examples-lockup        # tests for lockup examples
```

### Benchmarks

```shell
just benchmark-all               # benchmark Flow and Lockup
just benchmark <protocol>        # benchmark one protocol; protocol ∈ {flow, lockup}
just format-numbers              # post-process numbers + mdformat the results dir
```

The `benchmark` recipe runs the matching `benchmarks-<protocol>` Foundry profile and writes Markdown tables to `benchmarks/results/`.

### Format and Lint

```shell
just full-check                  # solhint + forge fmt --check + mdformat --check
just full-write                  # auto-fix all of the above
just fmt-check                   # forge fmt --check on benchmarks/ and examples/
just fmt-write                   # forge fmt on benchmarks/ and examples/
```

Solhint runs against the glob `{benchmarks,examples}/**/*.sol` (overridden in this package's `justfile`).
