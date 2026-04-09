# Sablier EVM Monorepo

Smart contracts for Sablier onchain token distribution protocol.

## Tech Stack

- **Language**: Solidity 0.8.29
- **Framework**: Foundry
- **Package Manager**: Bun
- **Task Runner**: Just
- **Testing**: Foundry with Bulloak (BTT)
- **Linting**: Solhint, Prettier, mdformat

## Monorepo Structure

```
├── airdrops/   # Merkle-based token distribution
├── bob/        # Price-target vaults with yield adapters + OTC escrow
├── flow/       # Open-ended token streaming
├── lockup/     # Fixed-term vesting and airdrops
└── utils/      # Shared utilities and comptroller
```

Each package has its own `CLAUDE.md` with protocol-specific context.

## Code Standards

- Line length: 120 characters
- Use NatSpec for all public/external functions
- Follow existing patterns in each package
- Tests use Branching Tree Technique (BTT) with `.tree` files

## Development Workflow

1. Base branch for PRs: `staging`
2. Run `just <package>::full-check` before committing
3. Generate BTT tests: `bulloak scaffold -wf path/to/file.tree`

## Security

All protocols are audited. See [SECURITY.md](./SECURITY.md) for bug bounty details.

## References

@justfile
@package.json
@CONTRIBUTING.md
