// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { FlashLoan_Integration_Shared_Test } from "./FlashLoan.t.sol";

contract FlashLoanFunction_Integration_Shared_Test is FlashLoan_Integration_Shared_Test {
    uint128 internal constant LIQUIDITY_AMOUNT = 8_755_001e18;

    function setUp() public virtual override {
        FlashLoan_Integration_Shared_Test.setUp();
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenAmountNotTooHigh() {
        _;
    }

    modifier whenAssetFlashLoanable() {
        if (!comptroller.isFlashAsset(dai)) {
            comptroller.toggleFlashAsset(dai);
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
