// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "erc3156/interfaces/IERC3156FlashLender.sol";

import { Constants } from "../../Constants.t.sol";

contract ReentrantFlashLoanReceiver is Constants, IERC3156FlashBorrower {
    function onFlashLoan(
        address initiator,
        address asset,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32 response) {
        initiator;
        amount;
        fee;
        data;
        IERC20(asset).approve({ spender: msg.sender, amount: amount + fee });
        IERC3156FlashLender(msg.sender).flashLoan({ receiver: this, token: asset, amount: amount, data: data });
        response = FLASH_LOAN_CALLBACK_SUCCESS;
    }
}
