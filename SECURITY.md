# Security

Ensuring the security of the Sablier Protocol is our utmost priority. We have dedicated significant efforts towards the
design and testing of the protocol to guarantee its safety and reliability. However, we are aware that security is a
continuous process. If you believe you have found a security vulnerability, please read the
[Bug Bounty Program](https://sablier.notion.site/bug-bounty) and share a report privately with us.

## Common Protocol Assumptions

All Sablier protocols have been developed with a number of common technical assumptions in mind. For a disclosure to
qualify as a vulnerability, it must adhere to these assumptions:

- The total supply of any ERC-20 token remains below 2<sup>128</sup> - 1, i.e., `type(uint128).max`.
- The `transfer` and `transferFrom` methods of any ERC-20 token strictly reduce the sender's balance by the transfer
  amount and increase the recipient's balance by the same amount. In other words, tokens that charge fees on transfers
  are not supported.
- An address' ERC-20 balance can only change as a result of a `transfer` call by the sender or a `transferFrom` call by
  an approved address. This excludes rebase tokens, interest-bearing tokens, and permissioned tokens where the admin can
  arbitrarily change balances.
- The token contract is not an ERC-20 representation of the native token of the chain. For example, the
  [$POL token](https://polygonscan.com/address/0x0000000000000000000000000000000000001010) on Polygon is not supported.
- The token contract has only one entry point.
- The token contract does not allow callbacks (e.g., ERC-777 is not supported).

## Airdrops

Sablier Airdrops Protocol has been developed with the following additional assumptions:

- Campaign creator does not fund an Airdrop campaign contract before deploying it through the Sablier Merkle Factory.

## Bob

Sablier Bob Protocol has been developed with the following additional assumptions:

### 1. Trusted Oracles

Vault creators choose their own oracles and bear full responsibility for oracle selection. The protocol intentionally
does not validate oracle staleness or the accuracy of the value returned. Depositors should verify the oracle address
and its reliability before depositing into any vault.

### 2. Curve Pool Slippage and Liquidity

By default, the Lido adapter relies on the Curve stETH/ETH pool for converting stETH back to ETH. This has important implications:

- **Extreme market conditions**: In extreme market conditions, unstaking may fail due to excessive slippage or
  insufficient liquidity.
- **Chainlink stETH/ETH oracle**: If the Chainlink stETH/ETH oracle becomes stale, the unstaking may fail.

In such extreme market conditions, Sablier admin may need to trigger unstaking via Lido withdrawal queue mechanism.

### 3. Manual Settlement

When the oracle price goes above the target price, the vault does not settle by itself. A deliberate action is required
to mark it as settled; until that step is taken, the vault remains active. If the price later falls back below the
target, the vault still stays active and the user cannot redeem their tokens.

## Flow

Flow has been developed with the following additional assumptions:

- A trust relationship is formed between the sender, recipient, and depositors participating in a stream. The recipient
  depends on the sender to fulfill their obligation to repay any debts incurred by the Flow stream. Likewise, depositors
  trust that the sender will not abuse the refund function to reclaim tokens.
- The token contract must implement `decimals()` with an immutable return value.
- The token contract's `decimals()` function must not return a value higher than 18.
- The `depletionTimeOf` function depends on the stream's rate per second. Therefore, any change in the rate per second
  will result in a new depletion time.
- There could be a minor discrepancy between the actual streamed amount and the expected amount. This is due to `rps`
  being an 18-decimal number, while users provide the amount per interval in the UI. If `rps` had infinite decimals,
  this discrepancy would not occur.
- When withdrawing from multiple streams using `batch` function, the minimum fee required to execute the batch is equal
  to the minimum fee required to withdraw from a single stream. This is intentional and expected behavior.

## Lockup

Sablier Lockup has been developed with the following additional assumptions:

- The number of segments/tranches should be such that creating a stream should not lead to an overflow of the block gas
  limit.
- There is no need for exponents greater than ~18.44 in `LockupDynamic` segments.
- Recipient contracts on the hook allowlist have gone through due diligence and are assumed to expose no risk to the
  Sablier protocol.
- When withdrawing from multiple streams either using `batch` or `withdrawMultiple` function, the minimum fee required
  to execute the transaction is equal to the minimum fee required to withdraw from a single stream. This is intentional
  and expected behavior.
- In case of price-gated streams, the oracle address is chosen by the sender at creation time. A malicious sender could
  set a custom oracle that they control to manipulate the stream's vesting outcome. Additionally, when a price-gated
  stream is created, it is not checked if the oracle returns the price for the deposited token or some other token. In
  such cases, integrators and recipients are requested to verify the oracle correctness on their own.
