---
name: etherscan-verification
description: Verify smart contracts on Etherscan-compatible block explorers. This skill should be used when the user asks to "verify contract", "verify on etherscan", "verify on chain scan". Handles standard verification, Etherscan V2 API for unsupported chains on foundry, proxy patterns, and factory-created contracts.
---

## Overview

Contract verification on Etherscan-compatible explorers using Foundry's `forge verify-contract`. Covers standard
verification, unsupported chains via Etherscan V2 API, proxy patterns, and factory-created contracts.

## When to Use

- Verify deployed smart contracts on Etherscan-compatible explorers
- Verify proxy contracts (ERC1967, UUPS)
- Verify factory-created contracts (CREATE2)
- Extract constructor arguments from deployment data

## Prerequisites

| Requirement      | How to Get                                        |
| ---------------- | ------------------------------------------------- |
| Foundry ≥1.3.6   | Run `forge -V` to check version                   |
| Contract address | From deployment broadcast or user                 |
| Chain ID         | From explorer or network configuration            |
| Explorer API key | From Etherscan account (works for V2 multi-chain) |
| Source code      | Must match deployed bytecode exactly              |

### Version Check

Before proceeding, verify Foundry version:

```bash
forge -V
```

**Stop if version is below 1.3.6.**

## Verification Methods

### Method 1: Standard (Native Support)

For chains Foundry supports natively:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --rpc-url <chain_name> \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

### Method 2: Etherscan V2 API (Unsupported Chains on Foundry)

When Foundry shows "No known Etherscan API URL for chain X":

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --watch
```

Supported chains: https://docs.etherscan.io/supported-chains

### Method 3: With Constructor Arguments

For contracts with constructor parameters:

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --verifier etherscan \
  --verifier-url "https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>" \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args <ABI_ENCODED_ARGS> \
  --watch
```

Generate constructor args with `cast abi-encode`:

```bash
cast abi-encode "constructor(address,uint256)" 0x123... 1000
```

## Special Cases

Reference: `./references/special-cases.md`

### Proxy Contracts

Verify implementation and proxy separately. See reference for ERC1967 pattern.

### Factory-Created Contracts

Extract constructor args from broadcast `initCode` using `scripts/extract_constructor_args.py`.

### Library Verification

For libraries, use full path:

```bash
src/libraries/<Library>.sol:<Library>
```

## Troubleshooting

Reference: `./references/troubleshooting.md`

### Common Issues

| Error                        | Cause                | Solution                                    |
| ---------------------------- | -------------------- | ------------------------------------------- |
| "No known Etherscan API URL" | Chain not in Foundry | Use `--verifier-url` with V2 API            |
| "Bytecode does not match"    | Compilation drift    | Checkout deployment commit + reinstall deps |
| "Constructor args mismatch"  | Wrong/missing args   | Extract from broadcast or encode manually   |
| "Already verified"           | Previously verified  | No action needed                            |

## Output

After successful verification:

- Contract source visible on explorer
- ABI available for interaction
- Constructor args decoded
- "Contract Source Code Verified" badge

## Examples

Reference: `./references/examples.md` for real-world verification examples from Monad deployment.
