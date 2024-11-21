// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @dev This contract implements neither the receive nor the fallback function.
/// See https://ethereum.stackexchange.com/a/78374/24693
contract ContractWithoutReceiveEth { }

/// @dev This contract implements the receive function.
contract ContractWithReceiveEth {
    receive() external payable { }
}
