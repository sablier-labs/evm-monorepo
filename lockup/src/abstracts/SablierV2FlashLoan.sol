// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

import { IERC3156FlashBorrower } from "../interfaces/erc3156/IERC3156FlashBorrower.sol";
import { IERC3156FlashLender } from "../interfaces/erc3156/IERC3156FlashLender.sol";
import { Errors } from "../libraries/Errors.sol";
import { SablierV2Base } from "./SablierV2Base.sol";

/// @title SablierV2FlashLoan
/// @notice This contract implements the ERC-3156 standard to enable flash loans.
/// @dev See https://eips.ethereum.org/EIPS/eip-3156.
abstract contract SablierV2FlashLoan is
    IERC3156FlashLender, // 0 inherited components
    SablierV2Base // 4 inherited components
{
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a flash loan is executed.
    /// @param initiator The address of the flash loan initiator.
    /// @param receiver The address of the flash borrower.
    /// @param asset The address of the ERC-20 asset that has been flash loaned.
    /// @param amount The amount of `asset` flash loaned.
    /// @param feeAmount The fee amount of `asset` charged by the protocol.
    /// @param data The data passed to the flash borrower.
    event FlashLoan(
        address indexed initiator,
        IERC3156FlashBorrower indexed receiver,
        IERC20 indexed asset,
        uint256 amount,
        uint256 feeAmount,
        bytes data
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 INTERNAL CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    bytes32 internal constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The amount of fees to charge for a hypothetical flash loan amount.
    ///
    /// @dev You might notice a bit of a terminology clash here, since the ERC-3156 standard refers to the "flash fee"
    /// as an amount, whereas the flash fee retrieved from the comptroller is a percentage. Throughout the code base,
    /// the "amount" suffix is typically appended to variables that represent amounts, but, in this context, the name
    /// must be kept unchanged to comply with the ERC.
    ///
    /// Requirements:
    /// - The ERC-20 asset must be flash loanable.
    ///
    /// @param asset The ERC-20 asset to flash loan.
    /// @param amount The amount of `asset` flash loaned.
    /// @return fee The amount of `asset` to charge for the loan on top of the returned principal.
    function flashFee(address asset, uint256 amount) public view override returns (uint256 fee) {
        // Checks: the ERC-20 asset is flash loanable.
        if (!comptroller.isFlashAsset(IERC20(asset))) {
            revert Errors.SablierV2FlashLoan_AssetNotFlashLoanable(IERC20(asset));
        }

        // Calculate the flash fee.
        fee = ud(amount).mul(comptroller.flashFee()).intoUint256();
    }

    /// @notice The amount of ERC-20 assets available for flash loan.
    /// @dev If the ERC-20 asset is not flash loanable, this function returns zero.
    /// @param asset The address of the ERC-20 asset to query.
    /// @return amount The amount of `asset` that can be flash loaned.
    function maxFlashLoan(address asset) external view override returns (uint256 amount) {
        // The default value is zero, so it doesn't have to be explicitly set.
        if (comptroller.isFlashAsset(IERC20(asset))) {
            amount = IERC20(asset).balanceOf(address(this));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Allows smart contracts to access the entire liquidity of the Sablier V2 contract within one
    /// transaction as long as the principal plus a flash fee is returned.
    ///
    /// @dev Emits a {FlashLoan} event.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - Refer to the requirements in {flashFee}.
    /// - `amount` must be less than 2^128.
    /// - `fee` must be less than 2^128.
    /// - `amount` must not exceed the liquidity available for `asset`.
    /// - `msg.sender` must allow this contract to spend at least `amount + fee` assets.
    /// - `receiver` implementation of {IERC3156FlashBorrower.onFlashLoan} must return `CALLBACK_SUCCESS`.
    ///
    /// @param receiver The receiver of the flash loaned assets, and the receiver of the callback.
    /// @param asset The address of the ERC-20 asset to use for flash borrowing.
    /// @param amount The amount of `asset` to flash loan.
    /// @param data Arbitrary data structure, intended to contain user-defined parameters.
    /// @return success `true` on success.
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address asset,
        uint256 amount,
        bytes calldata data
    )
        external
        override
        noDelegateCall
        returns (bool success)
    {
        // Checks: the amount is less than 2^128. This prevents the below calculations from overflowing.
        if (amount > type(uint128).max) {
            revert Errors.SablierV2FlashLoan_AmountTooHigh(amount);
        }

        // Calculate the flash fee. This also checks that the ERC-20 asset is flash loanable.
        uint256 fee = flashFee(asset, amount);

        // Checks: the calculated fee is less than 2^128. This check can fail only when the comptroller flash fee
        // is set to an abnormally high value.
        if (fee > type(uint128).max) {
            revert Errors.SablierV2FlashLoan_CalculatedFeeTooHigh(fee);
        }

        // Interactions: perform the ERC-20 transfer to flash loan the assets to the borrower.
        IERC20(asset).safeTransfer({ to: address(receiver), value: amount });

        // Interactions: perform the borrower callback.
        bytes32 response =
            receiver.onFlashLoan({ initiator: msg.sender, asset: asset, amount: amount, fee: fee, data: data });

        // Checks: the response matches the expected callback success hash.
        if (response != CALLBACK_SUCCESS) {
            revert Errors.SablierV2FlashLoan_FlashBorrowFail();
        }

        uint256 returnAmount;

        // Using unchecked arithmetic because the checks above prevent these calculations from overflowing.
        unchecked {
            // Effects: record the flash fee amount in the protocol revenues. The casting to uint128 is safe due
            // to the check at the start of the function.
            protocolRevenues[IERC20(asset)] = protocolRevenues[IERC20(asset)] + uint128(fee);

            // Calculate the amount that the borrower must return.
            returnAmount = amount + fee;
        }

        // Interactions: perform the ERC-20 transfer to get the principal back plus the fee.
        IERC20(asset).safeTransferFrom({ from: address(receiver), to: address(this), value: returnAmount });

        // Log the flash loan.
        emit FlashLoan({
            initiator: msg.sender,
            receiver: receiver,
            asset: IERC20(asset),
            amount: amount,
            feeAmount: fee,
            data: data
        });

        // Set the success flag.
        success = true;
    }
}
