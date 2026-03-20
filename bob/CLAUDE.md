# Sablier Bob and Escrow

@../CLAUDE.md

This package contains the following protocols:

## Sablier Bob

Price-gated vault protocol for conditional token releases with optional yield generation.

### Protocol Overview

Bob enables entering ERC-20 tokens into vaults that release based on price conditions. Key features:

- **Price-gated vaults**: Tokens locked until target price reached (SETTLED) or expiry passes (EXPIRED)
- **Oracle integration**: Chainlink-compatible price feeds with manual sync
- **Yield adapters**: Optional Lido integration for staking deposited tokens (WETH -> wstETH)
- **Comptrollerable**: Admin functions and fee collection via comptroller contract

Uses singleton architecture - all vaults managed in `SablierBob` contract.

### Key Concepts

- **Vault ID**: Unique identifier for each vault
- **Vault Status**: Three states — `ACTIVE` (accepting deposits), `SETTLED` (synced price >= target), `EXPIRED` (expiry time passed). Both SETTLED and EXPIRED allow redemption.
- **Share Token**: `BobVaultShare` ERC-20 minted per vault on `enter()` (1:1 with deposited tokens). Transfers trigger `onShareTransfer()` to sync adapter attribution.
- **Manual Settlement**: Vaults do NOT auto-settle. Someone must call `syncPriceFromOracle()`, `enter()`, or `redeem()` to update `lastSyncedPrice`. Once synced at/above target, the vault stays SETTLED permanently even if the live price drops.
- **Adapter**: Optional yield strategy (currently Lido). Yield fee is snapshotted at vault creation and immune to later changes.

### Key Functions

- **`enter()`**: Deposit tokens into a vault, receive share tokens
- **`syncPriceFromOracle()`**: Anyone can call to update vault price from oracle
- **`redeem()`**: Burn shares for tokens after settlement/expiry. Non-adapter vaults require ETH fee via `msg.value` (minimum threshold). Adapter vaults deduct yield fee from staking rewards.
- **`unstakeTokensViaAdapter()`**: Anyone can call on a non-active adapter vault to unstake all tokens before individual redemptions

## Sablier Escrow

Over-the-counter (OTC) token swap protocol that allows users to swap ERC-20 tokens with each other.

### Key Concepts

- **Order ID**: Unique identifier for each order
- **Order Status**: Four states — `OPEN`, `FILLED`, `CANCELLED`, `EXPIRED`
- **Seller**: The address that created the order and deposited the sell token
- **Buyer**: The address that filled the order. `address(0)` means open order (anyone can fill); specific address means private order.
- **Sell Token**: The ERC-20 token being sold, deposited by the seller when the order is created
- **Buy Token**: The ERC-20 token the seller wants to receive
- **Sell Amount**: The amount of sell token that the seller is willing to exchange
- **Min Buy Amount**: The minimum amount of buy token required to fill the order. Buyer can pay more for price improvement.
- **Expiry Time** (`expiryTime`): The Unix timestamp when the order expires. `0` means the order never expires.
- **Trade Fee**: Percentage fee (max 2%) deducted from both sell and buy amounts on fill. Sent to comptroller contract.

## Package Structure

```
src/
├── SablierBob.sol              # Main vault contract
├── SablierEscrow.sol           # OTC swap contract
├── SablierLidoAdapter.sol      # Lido yield adapter
├── BobVaultShare.sol           # ERC-20 share token
├── abstracts/                  # Shared base contracts
├── interfaces/                 # Public interfaces
├── libraries/                  # Helper libraries
└── types/                      # Structs, enums
tests/
├── bob/                        # Bob-specific tests
└── escrow/                     # Escrow-specific tests
scripts/
└── solidity/                   # Deployment scripts
```

## Commands

```bash
just bob::build                       # Build
just bob::build-optimized             # Build with optimized profile
just bob::full-check                  # All checks
just bob::test                        # Run tests
just bob::test-lite                   # Run tests without fork tests
just bob::test-optimized              # Run tests with optimized profile
just bob::test-bulloak                # Verify BTT structure
just bob::coverage                    # Coverage report
```
