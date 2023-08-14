// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { UD60x18, ud } from "@prb/math/src/UD60x18.sol";

import { IERC3156FlashBorrower } from "src/interfaces/erc3156/IERC3156FlashBorrower.sol";
import { Errors } from "src/libraries/Errors.sol";

import { FlashLoanFunction_Integration_Shared_Test } from "../../shared/flash-loan/flashLoanFunction.t.sol";

contract FlashLoanFunction_Integration_Fuzz_Test is FlashLoanFunction_Integration_Shared_Test {
    function setUp() public virtual override {
        FlashLoanFunction_Integration_Shared_Test.setUp();
    }

    function testFuzz_RevertWhen_AmountTooHigh(uint256 amount) external whenNotDelegateCalled {
        amount = _bound(amount, uint256(MAX_UINT128) + 1, MAX_UINT256);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_AmountTooHigh.selector, amount));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(dai),
            amount: amount,
            data: bytes("")
        });
    }

    function testFuzz_RevertWhen_CalculatedFeeTooHigh(UD60x18 flashFee)
        external
        whenNotDelegateCalled
        whenAmountNotTooHigh
        whenAssetFlashLoanable
    {
        // Bound the flash fee so that the calculated fee ends up being greater than 2^128.
        flashFee = _bound(flashFee, ud(1.1e18), ud(10e18));
        comptroller.setFlashFee(flashFee);

        // Run the test.
        uint256 fee = flashLoan.flashFee({ asset: address(dai), amount: MAX_UINT128 });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2FlashLoan_CalculatedFeeTooHigh.selector, fee));
        flashLoan.flashLoan({
            receiver: IERC3156FlashBorrower(address(0)),
            asset: address(dai),
            amount: MAX_UINT128,
            data: bytes("")
        });
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - Multiple values for the comptroller flash fee, including zero
    /// - Multiple values for the flash loan amount, including zero
    /// - Multiple values for the data bytes array, including zero length
    function testFuzz_FlashLoanFunction(
        UD60x18 comptrollerFlashFee,
        uint128 amount,
        bytes calldata data
    )
        external
        whenNotDelegateCalled
        whenAmountNotTooHigh
        whenAssetFlashLoanable
        whenCalculatedFeeNotTooHigh
        whenBorrowDoesNotFail
        whenNoReentrancy
    {
        comptrollerFlashFee = _bound(comptrollerFlashFee, 0, MAX_FEE);
        comptroller.setFlashFee(comptrollerFlashFee);

        // Load the initial protocol revenues.
        uint128 initialProtocolRevenues = flashLoan.protocolRevenues(dai);

        // Load the flash fee.
        uint256 fee = flashLoan.flashFee({ asset: address(dai), amount: amount });

        // Mint the flash loan amount to the contract.
        deal({ token: address(dai), to: address(flashLoan), give: amount });

        // Mint the flash fee to the receiver so that they can repay the flash loan.
        deal({ token: address(dai), to: address(goodFlashLoanReceiver), give: fee });

        // Expect `amount` of assets to be transferred from {SablierV2FlashLoan} to the receiver.
        expectCallToTransfer({ to: address(goodFlashLoanReceiver), amount: amount });

        // Expect `amount+fee` of assets to be transferred back from the receiver.
        uint256 returnAmount = amount + fee;
        expectCallToTransferFrom({ from: address(goodFlashLoanReceiver), to: address(flashLoan), amount: returnAmount });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(flashLoan) });
        emit FlashLoan({
            initiator: users.admin,
            receiver: goodFlashLoanReceiver,
            asset: dai,
            amount: amount,
            feeAmount: fee,
            data: data
        });

        // Execute the flash loan.
        bool response =
            flashLoan.flashLoan({ receiver: goodFlashLoanReceiver, asset: address(dai), amount: amount, data: data });

        // Assert that the returned response is `true`.
        assertTrue(response, "flashLoan response");

        // Assert that the protocol fee has been recorded.
        uint128 actualProtocolRevenues = flashLoan.protocolRevenues(dai);
        uint128 expectedProtocolRevenues = initialProtocolRevenues + uint128(fee);
        assertEq(actualProtocolRevenues, expectedProtocolRevenues, "protocolRevenues");
    }
}
