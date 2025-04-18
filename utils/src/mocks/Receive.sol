// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

contract ContractWithoutReceive { }

contract ContractWithReceive {
    receive() external payable { }
}
