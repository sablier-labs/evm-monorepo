// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC3156FlashBorrower } from "../../../src/interfaces/erc3156/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../../../src/interfaces/erc3156/IERC3156FlashLender.sol";

import { Constants } from "../../utils/Constants.sol";

contract ReentrantFlashLoanReceiver is Constants, IERC3156FlashBorrower {
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
        IERC20(asset).approve({ spender: msg.sender, amount: amount + fee });
        IERC3156FlashLender(msg.sender).flashLoan({ receiver: this, asset: asset, amount: amount, data: data });
        response = FLASH_LOAN_CALLBACK_SUCCESS;
    }
}
