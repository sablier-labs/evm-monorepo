// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC3156FlashBorrower } from "../../../src/interfaces/erc3156/IERC3156FlashBorrower.sol";

contract FaultyFlashLoanReceiver is IERC3156FlashBorrower {
    bytes32 internal constant FAULTY_RESPONSE = keccak256("This is a faulty response");

    function onFlashLoan(
        address initiator,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    )
        external
        returns (bytes32 response)
    {
        initiator;
        data;
        IERC20(asset).approve({ spender: msg.sender, amount: amount + fee });
        response = FAULTY_RESPONSE;
    }
}
