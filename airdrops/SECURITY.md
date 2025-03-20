# Security

Ensuring the security of the Sablier Protocol is our utmost priority. We have dedicated significant efforts towards the
design and testing of the protocol to guarantee its safety and reliability. However, we are aware that security is a
continuous process. If you believe you have found a security vulnerability, please read the
[Bug Bounty Program](https://sablier.notion.site/bug-bounty), and share a report privately with us.

## Protocol Assumptions

Sablier Airdrops has been developed with a number of technical assumptions in mind. For a disclosure to qualify as a
vulnerability, it must adhere to these assumptions as well:

- The total supply of any ERC-20 token remains below 2<sup>128</sup> - 1, i.e., `type(uint128).max`.
- The `transfer` and `transferFrom` methods of any ERC-20 token strictly reduce the sender's balance by the transfer
  amount and increase the recipient's balance by the same amount. In other words, tokens that charge fees on transfers
  are not supported.
- An address' ERC-20 balance can only change as a result of a `transfer` call by the sender or a `transferFrom` call by
  an approved address. This excludes rebase tokens and interest-bearing tokens.
- The token contract is not an ERC-20 representation of the native token of the chain. For example, the
  [$POL token](https://polygonscan.com/address/0x0000000000000000000000000000000000001010) on Polygon is not supported.
- The token contract has only one entry point.
- The token contract does not allow callbacks (e.g. ERC-777 is not supported).
