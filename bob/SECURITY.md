# Security

This document outlines security considerations, assumptions, and known limitations for protocols in this package.

## Bug Bounty

See the main repository [SECURITY.md](../SECURITY.md) for common assumptions and bug bounty details.

## Protocol Assumptions - Sablier Bob

### 1. Trusted Oracles

Vault creators choose their own oracles and bear full responsibility for oracle selection. The protocol intentionally
does not validate oracle staleness or the accuracy of the value returned. Depositors should verify the oracle address
and its reliability before depositing into any vault.

### 2. Curve Pool Slippage and Liquidity

The Lido adapter relies on the Curve stETH/ETH pool for converting stETH back to ETH. This has important implications:

- **Extreme market conditions**: In extreme market conditions, unstaking may fail due to excessive slippage or
  insufficient liquidity.

### 3. Manual Settlement

When the oracle price goes above the target price, the vault does not settle by itself. A deliberate action is required
to mark it as settled; until that step is taken, the vault remains active. If the price later falls back below the
target, the vault still stays active and the user cannot redeem their tokens.
