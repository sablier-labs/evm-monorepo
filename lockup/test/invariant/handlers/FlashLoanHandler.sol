// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";
import { IERC3156FlashBorrower } from "src/interfaces/erc3156/IERC3156FlashBorrower.sol";
import { ISablierV2Comptroller } from "src/interfaces/ISablierV2Comptroller.sol";

import { TimestampStore } from "../stores/TimestampStore.sol";
import { BaseHandler } from "./BaseHandler.sol";

/// @dev This contract and not {SablierV2FlashLoan} is exposed to Foundry for invariant testing. The point is
/// to bound and restrict the inputs that get passed to the real-world contract to avoid getting reverts.
contract FlashLoanHandler is BaseHandler {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierV2Comptroller public comptroller;
    SablierV2FlashLoan public flashLoanContract;
    IERC3156FlashBorrower internal receiver;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(
        IERC20 asset_,
        TimestampStore timestampStore_,
        ISablierV2Comptroller comptroller_,
        SablierV2FlashLoan flashLoanContract_,
        IERC3156FlashBorrower receiver_
    )
        BaseHandler(asset_, timestampStore_)
    {
        comptroller = comptroller_;
        flashLoanContract = flashLoanContract_;
        receiver = receiver_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               SABLIER-V2-FLASH-LOAN
    //////////////////////////////////////////////////////////////////////////*/

    function flashLoan(
        uint256 timeJumpSeed,
        uint128 amount
    )
        external
        instrument("flashLoan")
        adjustTimestamp(timeJumpSeed)
    {
        // Only up to `MAX_UINT128` assets can be flash loaned.
        uint256 balance = asset.balanceOf(address(this));
        uint128 upperBound = uint128(Math.min(balance, MAX_UINT128));
        amount = boundUint128(amount, 0, upperBound);

        // Only supported assets can be flash loaned.
        bool isFlashAsset = comptroller.isFlashAsset(asset);
        if (!isFlashAsset) {
            return;
        }

        // The flash fee must be less than or equal to `MAX_UINT128`.
        uint256 fee = flashLoanContract.flashFee(address(asset), amount);
        if (fee > type(uint128).max) {
            return;
        }

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(asset), to: address(receiver), give: fee });

        // Some contracts do not inherit from {SablierV2FlashLoan}.
        (bool success,) = address(flashLoanContract).staticcall(
            abi.encodeWithSelector(
                SablierV2FlashLoan.flashLoan.selector, receiver, address(asset), amount, bytes("Some Data")
            )
        );
        if (!success) {
            return;
        }

        // Execute the flash loan.
        flashLoanContract.flashLoan({
            receiver: receiver,
            asset: address(asset),
            amount: amount,
            data: bytes("Some Data")
        });
    }
}
