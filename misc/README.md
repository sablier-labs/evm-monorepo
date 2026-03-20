# Sablier EVM Examples and Benchmarks

This repository contains the following miscellaneous contracts:

- [Examples](examples): Example integrations with the Sablier Protocol. More detailed guides walking through the logic
  of the examples can be found on the [Sablier docs](https://docs.sablier.com) website.
- [Benchmarks](benchmarks): Scripts for generating gas benchmarks for Sablier EVM protocols. The benchmark tables are located in the [results](/results) folder, but they can also be viewed on
  [docs.sablier.com](https://docs.sablier.com).

## Commands

To generate the benchmark table for [Sablier Lockup](https://github.com/sablier-labs/lockup), run the following command:

```bash
just lockup::benchmark
```

To generate the benchmark table for [Sablier Flow](https://github.com/sablier-labs/flow), run the following command:

```bash
just flow::benchmark
```

## Disclaimer

The examples provided in this repo have NOT BEEN AUDITED and is provided "AS IS" with no warranties of any kind, either
express or implied. It is intended solely for demonstration purposes. These examples should NOT be used in a production
environment. It makes specific assumptions that may not apply to your particular needs.

## Contributing

Make sure you have [Foundry](https://github.com/foundry-rs/foundry) installed, and that you have it configured correctly
in [VSCode](https://book.getfoundry.sh/config/vscode).

## License

This repo is licensed under GPL 3-0 or later.
