// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";

contract FlashLoanFunction_Shared_Test is Base_Test {
    uint128 internal constant LIQUIDITY_AMOUNT = 8_755_001e18;

    function setUp() public virtual override { }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenAmountNotTooHigh() {
        _;
    }

    modifier whenAssetFlashLoanable() {
        if (!comptroller.isFlashAsset(usdc)) {
            comptroller.toggleFlashAsset(usdc);
        }
        _;
    }

    modifier whenCalculatedFeeNotTooHigh() {
        _;
    }

    modifier whenBorrowDoesNotFail() {
        _;
    }

    modifier whenNoReentrancy() {
        _;
    }
}
