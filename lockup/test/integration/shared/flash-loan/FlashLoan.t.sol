// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";

import { FlashLoanMock } from "../../../mocks/flash-loan/FlashLoanMock.sol";
import { Integration_Test } from "../../Integration.t.sol";

/// @notice Common testing logic needed by all {SablierV2FlashLoan} integration tests.
abstract contract FlashLoan_Integration_Shared_Test is Integration_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2FlashLoan internal flashLoan;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Deploy the flash loan mock.
        flashLoan = new FlashLoanMock(users.admin, comptroller);

        // Set the default flash fee in the comptroller.
        comptroller.setFlashFee({ newFlashFee: defaults.FLASH_FEE() });
    }
}
