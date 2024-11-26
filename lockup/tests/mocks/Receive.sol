// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

contract ContractWithoutReceive { }

contract ContractWithReceive {
    receive() external payable { }
}
