// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

/// @dev This contract does not implement receive ether or fallback function.
contract ContractWithoutReceiveEth { }

/// @dev This contract implements receive ether function.
contract ContractWithReceiveEth {
    receive() external payable { }
}
