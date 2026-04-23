---
name: explorer-contract-verification
description: Verify smart contracts on Etherscan, Routescan, and Blockscout block explorers. This skill should be used when the user asks to "verify contract", "verify on etherscan", "verify on blockscout", "verify on routescan", "verify on chain scan". Handles standard verification, Etherscan V2 API, Routescan, Blockscout verification, proxy patterns, and factory-created contracts.
---

## Overview

Contract verification on Etherscan, Routescan, and Blockscout explorers using Foundry's `forge verify-contract`. Covers
standard Etherscan verification, unsupported chains via Etherscan V2 API, Routescan, Blockscout verification, proxy
patterns, and factory-created contracts.

## When to Use

- Verify deployed smart contracts on Etherscan, Routescan, or Blockscout explorers
- Verify proxy contracts (ERC1967, UUPS)
- Verify factory-created contracts (CREATE2)
- Extract constructor arguments from deployment data

## Prerequisites

| Requirement      | How to Get                                     |
| ---------------- | ---------------------------------------------- |
| Foundry ≥1.3.6   | Run `forge -V` to check version                |
| Contract address | From deployment broadcast or user              |
| Chain ID         | From explorer or network configuration         |
| Explorer API key | From Etherscan account (Etherscan chains only) |
| Source code      | Must match deployed bytecode exactly           |

### Version Check

Before proceeding, verify Foundry version:

```bash
forge -V
```

**Stop if version is below 1.3.6.**

## Chain Reference

Determine the correct verification method by looking up the target chain below.

### Etherscan Chains

| Chain            | Chain ID | Method       |
| ---------------- | -------- | ------------ |
| abstract         | 2741     | Etherscan V2 |
| arbitrum         | 42161    | Native or V2 |
| base             | 8453     | Native or V2 |
| berachain        | 80094    | Etherscan V2 |
| bsc              | 56       | Native or V2 |
| ethereum         | 1        | Native or V2 |
| gnosis           | 100      | Native or V2 |
| linea            | 59144    | Etherscan V2 |
| optimism         | 10       | Native or V2 |
| polygon          | 137      | Native or V2 |
| scroll           | 534352   | Etherscan V2 |
| sonic            | 146      | Etherscan V2 |
| unichain         | 130      | Etherscan V2 |
| arbitrum_sepolia | 421614   | Native or V2 |
| base_sepolia     | 84532    | Native or V2 |
| optimism_sepolia | 11155420 | Native or V2 |
| sepolia          | 11155111 | Native or V2 |

### Routescan Chains

| Chain     | Chain ID | Verifier URL                                                          |
| --------- | -------- | --------------------------------------------------------------------- |
| avalanche | 43114    | `https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan/api` |
| chiliz    | 88888    | `https://api.routescan.io/v2/network/mainnet/evm/88888/etherscan/api` |

### Blockscout Chains

| Chain     | Chain ID | Verifier URL                           |
| --------- | -------- | -------------------------------------- |
| lightlink | 1890     | `https://phoenix.lightlink.io/api/`    |
| mode      | 34443    | `https://explorer.mode.network/api/`   |
| morph     | 2818     | `https://explorer-api.morphl2.io/api/` |
| superseed | 5330     | `https://explorer.superseed.xyz/api/`  |

## Verification Methods

### Method 1: Etherscan — Native Support

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

### Method 2: Etherscan V2 API

When Foundry shows "No known Etherscan API URL for chain X", or for any Etherscan chain:

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

### Method 3: Routescan

For chains using Routescan explorers (avalanche, chiliz). Look up the verifier URL from the Routescan Chains table
above. Uses `--verifier etherscan` with a Routescan URL.

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --verifier etherscan \
  --verifier-url "<ROUTESCAN_VERIFIER_URL>" \
  --etherscan-api-key "verifyContract" \
  --watch
```

> **Note:** Routescan does not require a real API key — pass `"verifyContract"` as the value.

### Method 4: Blockscout

For chains using Blockscout explorers. Look up the verifier URL from the Blockscout Chains table above.

```bash
FOUNDRY_PROFILE=optimized forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/<Contract>.sol:<Contract> \
  --verifier blockscout \
  --verifier-url "<BLOCKSCOUT_VERIFIER_URL>" \
  --etherscan-api-key "verifyContract" \
  --watch
```

> **Note:** Blockscout does not require a real API key — pass `"verifyContract"` as the value.

### Constructor Arguments

Append `--constructor-args` to any method above when the contract has constructor parameters:

```bash
--constructor-args <ABI_ENCODED_ARGS>
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
