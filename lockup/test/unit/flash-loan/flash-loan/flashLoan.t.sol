// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";
import { IERC3156FlashBorrower } from "erc3156/contracts/interfaces/IERC3156FlashBorrower.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { FlashLoan_Test } from "../FlashLoan.t.sol";

contract FlashLoanFunction_Test is FlashLoan_Test {
    address internal asset = address(dai);

    /// @dev it should revert.
    function test_RevertWhen_AmountTooHigh(uint256 amount) external {
        amount = bound(amount, uint256(UINT128_MAX) + 1, UINT256_MAX);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AmountTooHigh.selector, amount));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: asset,
            amount: amount,
            data: bytes("")
        });
    }

    modifier amountNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotFlashLoanable() external amountNotTooHigh {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AssetNotFlashLoanable.selector, dai));
        flashLoan.flashLoan({ receiver: IERC3156FlashBorrower(address(0)), asset: asset, amount: 0, data: bytes("") });
    }

    modifier assetFlashLoanable() {
        comptroller.toggleFlashAsset(IERC20(asset));
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CalculatedFeeTooHigh(UD60x18 flashFee) external amountNotTooHigh assetFlashLoanable {
        // Bound the flash fee so that the calculated fee ends up being greater than 2^128.
        flashFee = bound(flashFee, ud(1.1e18), ud(10e18));
        comptroller.setFlashFee(flashFee);

        uint256 fee = flashLoan.flashFee({ asset: asset, amount: UINT128_MAX });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_FeeTooHigh.selector, fee));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: asset,
            amount: UINT128_MAX,
            data: bytes("")
        });
    }

    modifier calculatedFeeNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_InsufficientAssetLiquidity(
        uint128 amount
    ) external amountNotTooHigh assetFlashLoanable calculatedFeeNotTooHigh {
        vm.assume(amount != 0);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2FlashLoan_InsufficientAssetLiquidity.selector,
                IERC20(asset),
                0,
                amount
            )
        );
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: asset,
            amount: amount,
            data: bytes("")
        });
    }

    modifier sufficientAssetLiquidity() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_BorrowFailed()
        external
        amountNotTooHigh
        assetFlashLoanable
        calculatedFeeNotTooHigh
        sufficientAssetLiquidity
    {
        uint256 amount = 100e18;
        deal({ token: asset, to: address(flashLoan), give: amount });
        vm.expectRevert(Errors.SablierV2FlashLoan_FlashBorrowFail.selector);
        flashLoan.flashLoan({ receiver: faultyFlashLoanReceiver, asset: asset, amount: amount, data: bytes("") });
    }

    modifier borrowDoesNotFail() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_Reentrancy()
        external
        amountNotTooHigh
        assetFlashLoanable
        calculatedFeeNotTooHigh
        sufficientAssetLiquidity
        borrowDoesNotFail
    {
        uint256 amount = 100e18;
        deal({ token: asset, to: address(flashLoan), give: amount * 2 });
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2FlashLoan_InsufficientAssetLiquidity.selector,
                IERC20(asset),
                0,
                amount / 2
            )
        );
        flashLoan.flashLoan({
            receiver: reentrantFlashLoanReceiver,
            asset: asset,
            amount: amount / 2,
            data: bytes("")
        });
    }

    modifier noReentrancy() {
        _;
    }

    /// @dev it should execute the flash loan, make the ERC-20 transfers, update the protocol revenues, and emit
    /// a FlashLoan event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the comptroller flash fee, including zero.
    /// - Multiple values for the flash loan amount, including zero.
    /// - Multiple values for the data bytes array, including zero length.
    function testFuzz_FlashLoan(
        UD60x18 comptrollerFlashFee,
        uint128 amount,
        bytes calldata data
    )
        external
        amountNotTooHigh
        assetFlashLoanable
        calculatedFeeNotTooHigh
        sufficientAssetLiquidity
        borrowDoesNotFail
        noReentrancy
    {
        comptrollerFlashFee = bound(comptrollerFlashFee, 0, DEFAULT_MAX_FEE);
        comptroller.setFlashFee(comptrollerFlashFee);

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = flashLoan.getProtocolRevenues(IERC20(asset));

        // Load the flash fee.
        uint256 fee = flashLoan.flashFee(asset, amount);

        // Deal the flash loan amount to the contract.
        deal({ token: asset, to: address(flashLoan), give: amount });

        // Deal the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: asset, to: address(goodFlashLoanReceiver), give: fee });

        // Expect `amount` of ERC-20 assets to be transferred from the {SablierV2FlashLoan} contract to the receiver.
        vm.expectCall(asset, abi.encodeCall(IERC20.transfer, (address(goodFlashLoanReceiver), amount)));

        // Expect `amount+fee` of ERC-20 assets to be transferred back from the receiver.
        uint256 returnAmount = amount + fee;
        vm.expectCall(
            asset,
            abi.encodeCall(IERC20.transferFrom, (address(goodFlashLoanReceiver), address(flashLoan), returnAmount))
        );

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.FlashLoan({
            initiator: users.admin,
            receiver: goodFlashLoanReceiver,
            asset: IERC20(asset),
            amount: amount,
            feeAmount: fee,
            data: data
        });

        // Execute the flash loan.
        bool response = flashLoan.flashLoan({
            receiver: goodFlashLoanReceiver,
            asset: asset,
            amount: amount,
            data: data
        });

        // Assert that the returned response is `true`.
        assertTrue(response);

        // Assert that the protocol fee was recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(IERC20(asset));
        uint128 expectedProtocolRevenues = initialProtocolRevenues + uint128(fee);
        assertEq(actualProtocolRevenues, expectedProtocolRevenues);
    }
}
