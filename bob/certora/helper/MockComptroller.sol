// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title MockComptroller
/// @notice Minimal mock for Certora verification. Provides a `receive()` function so that
///         low-level `call{value}` to the comptroller address resolves to a concrete contract,
///         enabling the prover to correctly model ETH balance transfers via `nativeBalances`.
///         Without this, the call is "unresolved" and the prover cannot track ETH leaving
///         SablierBob, causing false violations on the `noEthStuckInContract` rule.
contract MockComptroller {
    receive() external payable {}
}
