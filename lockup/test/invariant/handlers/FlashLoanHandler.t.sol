// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/utils/math/Math.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { BaseHandler } from "./BaseHandler.t.sol";

/// @title FlashLoanHandler
/// @dev This contract and not {SablierV2FlashLoan} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract FlashLoanHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 public asset;
    ISablierV2Comptroller public comptroller;
    SablierV2FlashLoan public flashLoanContract;
    IERC3156FlashBorrower internal receiver;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        ISablierV2Comptroller comptroller_,
        SablierV2FlashLoan flashLoanContract_,
        IERC3156FlashBorrower receiver_
    ) {
        asset = asset_;
        comptroller = comptroller_;
        flashLoanContract = flashLoanContract_;
        receiver = receiver_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    function flashLoan(uint128 amount) external instrument("flashLoan") {
        // Only up to `UINT128_MAX` assets can be flash loaned.
        uint256 balance = asset.balanceOf(address(this));
        uint128 upperBound = uint128(Math.min(balance, UINT128_MAX));
        amount = boundUint128(amount, 0, upperBound);

        // Only supported assets can be flash loaned.
        bool isFlashAsset = comptroller.isFlashAsset(asset);
        if (!isFlashAsset) {
            return;
        }

        // The flash fee must be less than or equal to `UINT128_MAX`.
        uint256 fee = flashLoanContract.flashFee(address(asset), amount);
        if (fee > type(uint128).max) {
            return;
        }

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(asset), to: address(receiver), give: fee });

        // Execute the flash loan.
        flashLoanContract.flashLoan({
            receiver: receiver,
            asset: address(asset),
            amount: amount,
            data: bytes("Some Data")
        });
    }
}
