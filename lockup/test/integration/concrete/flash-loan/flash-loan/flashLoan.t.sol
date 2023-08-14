// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { ud } from "@prb/math/src/UD60x18.sol";

import { IERC3156FlashLender } from "src/interfaces/erc3156/IERC3156FlashLender.sol";
import { Errors } from "src/libraries/Errors.sol";

import { FlashLoanFunction_Integration_Shared_Test } from "../../../shared/flash-loan/flashLoanFunction.t.sol";

contract FlashLoanFunction_Integration_Concrete_Test is FlashLoanFunction_Integration_Shared_Test {
    function setUp() public virtual override {
        FlashLoanFunction_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData =
            abi.encodeCall(IERC3156FlashLender.flashLoan, (goodFlashLoanReceiver, address(dai), 0, bytes("")));
        (bool success, bytes memory returnData) = address(flashLoan).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_AmountTooHigh() external whenNotDelegateCalled {
        uint256 amount = uint256(MAX_UINT128) + 1;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AmountTooHigh.selector, amount));
        flashLoan.flashLoan({ receiver: goodFlashLoanReceiver, asset: address(dai), amount: amount, data: bytes("") });
    }

    function test_RevertWhen_AssetNotFlashLoanable() external whenNotDelegateCalled whenAmountNotTooHigh {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AssetNotFlashLoanable.selector, dai));
        flashLoan.flashLoan({ receiver: goodFlashLoanReceiver, asset: address(dai), amount: 0, data: bytes("") });
    }

    function test_RevertWhen_CalculatedFeeTooHigh()
        external
        whenNotDelegateCalled
        whenAmountNotTooHigh
        whenAssetFlashLoanable
    {
        // Set the comptroller flash fee so that the calculated fee ends up being greater than 2^128.
        comptroller.setFlashFee({ newFlashFee: ud(1.1e18) });

        uint256 fee = flashLoan.flashFee({ asset: address(dai), amount: MAX_UINT128 });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_CalculatedFeeTooHigh.selector, fee));
        flashLoan.flashLoan({
            receiver: goodFlashLoanReceiver,
            asset: address(dai),
            amount: MAX_UINT128,
            data: bytes("")
        });
    }

    function test_RevertWhen_BorrowFailed()
        external
        whenNotDelegateCalled
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
    {
        deal({ token: address(dai), to: address(flashLoan), give: LIQUIDITY_AMOUNT });
        vm.expectRevert(Errors.SablierV2FlashLoan_FlashBorrowFail.selector);
        flashLoan.flashLoan({
            receiver: faultyFlashLoanReceiver,
            asset: address(dai),
            amount: LIQUIDITY_AMOUNT,
            data: bytes("")
        });
    }

    function test_RevertWhen_Reentrancy()
        external
        whenNotDelegateCalled
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
        whenBorrowDoesNotFail
    {
        uint256 amount = 100e18;
        deal({ token: address(dai), to: address(flashLoan), give: amount * 2 });
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        flashLoan.flashLoan({
            receiver: reentrantFlashLoanReceiver,
            asset: address(dai),
            amount: LIQUIDITY_AMOUNT / 4,
            data: bytes("")
        });
    }

    function test_FlashLoan()
        external
        whenNotDelegateCalled
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
        whenBorrowDoesNotFail
        whenNoReentrancy
    {
        // Mint the liquidity amount to the contract.
        deal({ token: address(dai), to: address(flashLoan), give: LIQUIDITY_AMOUNT });

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = flashLoan.protocolRevenues(dai);

        // Load the flash fee.
        uint256 fee = flashLoan.flashFee({ asset: address(dai), amount: LIQUIDITY_AMOUNT });

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(dai), to: address(goodFlashLoanReceiver), give: fee });

        // Expect `amount` of assets to be transferred to the receiver.
        expectCallToTransfer({ to: address(goodFlashLoanReceiver), amount: LIQUIDITY_AMOUNT });

        // Expect `amount+fee` of assets to be transferred back from the receiver.
        uint256 returnAmount = LIQUIDITY_AMOUNT + fee;
        expectCallToTransferFrom({ from: address(goodFlashLoanReceiver), to: address(flashLoan), amount: returnAmount });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(flashLoan) });
        bytes memory data = bytes("Hello World");
        emit FlashLoan({
            initiator: users.admin,
            receiver: goodFlashLoanReceiver,
            asset: dai,
            amount: LIQUIDITY_AMOUNT,
            feeAmount: fee,
            data: data
        });

        // Execute the flash loan.
        bool response = flashLoan.flashLoan({
            receiver: goodFlashLoanReceiver,
            asset: address(dai),
            amount: LIQUIDITY_AMOUNT,
            data: data
        });

        // Assert that the returned response is `true`.
        assertTrue(response, "flashLoan response");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = flashLoan.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + uint128(fee);
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
