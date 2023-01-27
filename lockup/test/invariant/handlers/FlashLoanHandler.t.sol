// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { GoodFlashLoanReceiver } from "../../shared/mockups/flash-loan/GoodFlashLoanReceiver.t.sol";
import { BaseHandler } from "./BaseHandler.t.sol";

/// @title FlashLoanHandler
/// @dev This contract and not {SablierV2FlashLoan} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract FlashLoanHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                               PUBLIC TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    ISablierV2Comptroller public comptroller;
    SablierV2FlashLoan public flashLoan;
    IERC3156FlashBorrower internal receiver;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        ISablierV2Comptroller comptroller_,
        SablierV2FlashLoan flashLoan_,
        IERC3156FlashBorrower receiver_
    ) {
        asset = asset_;
        comptroller = comptroller_;
        flashLoan = flashLoan_;
        receiver = receiver_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    function flashLoanFunction(uint128 amount) external instrument("flashLoan") {
        // Only supported ERC-20 assets can be flash loaned.
        bool isFlashLoanable = comptroller.isFlashLoanable(asset);
        if (!isFlashLoanable) {
            return;
        }

        // The flash fee must be less than or equal to type(uint128).max
        uint256 fee = flashLoan.flashFee(address(asset), amount);
        if (fee > type(uint128).max) {
            return;
        }

        // Mint the flash loan amount to the contract.
        deal({ token: address(asset), to: address(flashLoan), give: amount });

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(asset), to: address(receiver), give: fee });

        // Execute the flash loan.
        bool response = flashLoan.flashLoan({
            receiver: receiver,
            asset: address(asset),
            amount: amount,
            data: bytes("Some Data")
        });

        // Silence the compiler warning.
        response;
    }
}
