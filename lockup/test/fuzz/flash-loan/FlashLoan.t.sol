// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";

import { FlashLoanMock } from "../../shared/mockups/flash-loan/FlashLoanMock.t.sol";
import { Fuzz_Test } from "../Fuzz.t.sol";

/// @title FlashLoan_Fuzz_Test
/// @notice Common testing logic needed across {SablierV2FlashLoan} fuzz tests.
abstract contract FlashLoan_Fuzz_Test is Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2FlashLoan internal flashLoan;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Fuzz_Test.setUp();

        // Deploy the flash loan mock.
        flashLoan = new FlashLoanMock(users.admin, comptroller);

        // Set the default flash fee in the comptroller.
        comptroller.setFlashFee({ newFlashFee: DEFAULT_FLASH_FEE });

        // Make the default asset flash loanable.
        comptroller.toggleFlashAsset({ asset: DEFAULT_ASSET });
    }
}
