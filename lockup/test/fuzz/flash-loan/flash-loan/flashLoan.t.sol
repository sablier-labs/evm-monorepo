// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { MAX_UD60x18, UD60x18, ud } from "@prb/math/UD60x18.sol";
import { IERC3156FlashBorrower } from "erc3156/interfaces/IERC3156FlashBorrower.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { FlashLoan_Fuzz_Test } from "../FlashLoan.t.sol";

contract FlashLoanFunction_Fuzz_Test is FlashLoan_Fuzz_Test {
    /// @dev it should revert.
    function testFuzz_RevertWhen_AmountTooHigh(uint256 amount) external {
        amount = bound(amount, uint256(UINT128_MAX) + 1, UINT256_MAX);
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
    function testFuzz_RevertWhen_CalculatedFeeTooHigh(UD60x18 flashFee) external amountNotTooHigh {
        // Bound the flash fee so that the calculated fee ends up being greater than 2^128.
        flashFee = bound(flashFee, ud(1.1e18), ud(10e18));
        comptroller.setFlashFee(flashFee);

        // Run the test.
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

    /// @dev it should execute the flash loan, make the ERC-20 transfers, update the protocol revenues, and emit
    /// a {FlashLoan} event.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Multiple values for the comptroller flash fee, including zero.
    /// - Multiple values for the flash loan amount, including zero.
    /// - Multiple values for the data bytes array, including zero length.
    function testFuzz_FlashLoanFunction(
        UD60x18 comptrollerFlashFee,
        uint128 amount,
        bytes calldata data
    ) external amountNotTooHigh calculatedFeeNotTooHigh {
        comptrollerFlashFee = bound(comptrollerFlashFee, 0, DEFAULT_MAX_FEE);
        comptroller.setFlashFee(comptrollerFlashFee);

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
