# Security

Ensuring the security of the Sablier Protocol is our utmost priority. We have dedicated significant efforts towards the
design and testing of the protocol to guarantee its safety and reliability. However, we are aware that security is a
continuous process. If you believe you have found a security vulnerability, please read the
[Bug Bounty Program](https://sablier.notion.site/bug-bounty) and share a report privately with us.

## Protocol Assumptions

Flow has been developed with a number of technical assumptions in mind. For a disclosure to qualify as a vulnerability,
it must adhere to the following assumptions:

- The total supply of any ERC-20 token remains below $(2^{128} - 1)$, i.e., `type(uint128).max`.
- The `transfer` and `transferFrom` methods of any ERC-20 token strictly reduce the sender's balance by the transfer
  amount and increase the recipient's balance by the same amount. In other words, tokens that charge fees on transfers
  are not supported.
- An address' ERC-20 balance can only change as a result of a `transfer` call by the sender or a `transferFrom` call by
  an approved address. This excludes rebase tokens, interest-bearing tokens, and permissioned tokens where the admin can
  arbitrarily change balances.
- The token contract does not allow callbacks (e.g., ERC-777 is not supported).
- A trust relationship is formed between the sender, recipient, and depositors participating in a stream. The recipient
  depends on the sender to fulfill their obligation to repay any debts incurred by the Flow stream. Likewise, depositors
  trust that the sender will not abuse the refund function to reclaim tokens.
- The token contract must implement `decimals()` with an immutable return value.
- The `depletionTimeOf` function depends on the stream's rate per second. Therefore, any change in the rate per second
  will result in a new depletion time.
- As explained in the [Technical Documentation](https://github.com/sablier-labs/flow/blob/main/TECHNICAL-DOC.md), there
  could be a minor discrepancy between the actual streamed amount and the expected amount. This is due to `rps` being an
  18-decimal number, while users provide the amount per interval in the UI. If `rps` had infinite decimals, this
  discrepancy would not occur.
