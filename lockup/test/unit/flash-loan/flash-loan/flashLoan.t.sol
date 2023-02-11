// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { FlashLoan_Unit_Test } from "../FlashLoan.t.sol";

contract FlashLoanFunction_Unit_Test is FlashLoan_Unit_Test {
    /// @dev it should revert.
    function test_RevertWhen_AmountTooHigh() external {
        uint256 amount = uint256(UINT128_MAX) + 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AmountTooHigh.selector, amount));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
            amount: amount,
            data: bytes("")
        });
    }

    modifier amountNotTooHigh() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_AssetNotFlashLoanable() external amountNotTooHigh {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2FlashLoan_AssetNotFlashLoanable.selector, DEFAULT_ASSET)
        );
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
            amount: 0,
            data: bytes("")
        });
    }

    modifier assetFlashLoanable() {
        comptroller.toggleFlashAsset(DEFAULT_ASSET);
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CalculatedFeeTooHigh() external amountNotTooHigh assetFlashLoanable {
        // Set the comptroller flash fee so that the calculated fee ends up being greater than 2^128.
        comptroller.setFlashFee({ newFlashFee: ud(1.1e18) });

        uint256 fee = flashLoan.flashFee({ asset: address(DEFAULT_ASSET), amount: UINT128_MAX });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_CalculatedFeeTooHigh.selector, fee));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
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
                DEFAULT_ASSET,
                0,
                amount
            )
        );
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(DEFAULT_ASSET),
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
        deal({ token: address(DEFAULT_ASSET), to: address(flashLoan), give: amount });
        vm.expectRevert(Errors.SablierV2FlashLoan_FlashBorrowFail.selector);
        flashLoan.flashLoan({
            receiver: faultyFlashLoanReceiver,
            asset: address(DEFAULT_ASSET),
            amount: amount,
            data: bytes("")
        });
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
        deal({ token: address(DEFAULT_ASSET), to: address(flashLoan), give: amount * 2 });
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2FlashLoan_InsufficientAssetLiquidity.selector,
                DEFAULT_ASSET,
                0,
                amount / 2
            )
        );
        flashLoan.flashLoan({
            receiver: reentrantFlashLoanReceiver,
            asset: address(DEFAULT_ASSET),
            amount: amount / 2,
            data: bytes("")
        });
    }

    modifier noReentrancy() {
        _;
    }

    /// @dev it should execute the flash loan, make the ERC-20 transfers, update the protocol revenues, and emit
    /// a {FlashLoan} event.
    function test_FlashLoan()
        external
        amountNotTooHigh
        assetFlashLoanable
        calculatedFeeNotTooHigh
        sufficientAssetLiquidity
        borrowDoesNotFail
        noReentrancy
    {
        uint128 amount = 8_755_001e18;
        bytes memory data = bytes("Hello World");

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = flashLoan.getProtocolRevenues(DEFAULT_ASSET);

        // Load the flash fee.
        uint256 fee = flashLoan.flashFee({ asset: address(DEFAULT_ASSET), amount: amount });

        // Mint the flash loan amount to the contract.
        deal({ token: address(DEFAULT_ASSET), to: address(flashLoan), give: amount });

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(DEFAULT_ASSET), to: address(goodFlashLoanReceiver), give: fee });

        // Expect `amount` of ERC-20 assets to be transferred from the {SablierV2FlashLoan} contract to the receiver.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(IERC20.transfer, (address(goodFlashLoanReceiver), amount))
        );

        // Expect `amount+fee` of ERC-20 assets to be transferred back from the receiver.
        uint256 returnAmount = amount + fee;
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(IERC20.transferFrom, (address(goodFlashLoanReceiver), address(flashLoan), returnAmount))
        );

        // Expect a {FlashLoan} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
        emit Events.FlashLoan({
            initiator: users.admin,
            receiver: goodFlashLoanReceiver,
            asset: DEFAULT_ASSET,
            amount: amount,
            feeAmount: fee,
            data: data
        });

        // Execute the flash loan.
        bool response = flashLoan.flashLoan({
            receiver: goodFlashLoanReceiver,
            asset: address(DEFAULT_ASSET),
            amount: amount,
            data: data
        });

        // Assert that the returned response is `true`.
        assertTrue(response, "flashLoan response");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = linear.getProtocolRevenues(DEFAULT_ASSET);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + uint128(fee);
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
