// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { SablierV2FlashLoan } from "src/abstracts/SablierV2FlashLoan.sol";

import { Unit_Test } from "../Unit.t.sol";

/// @title FlashLoan_Unit_Test
/// @notice Common testing logic needed across {SablierV2FlashLoan} unit tests.
abstract contract FlashLoan_Unit_Test is Unit_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2FlashLoan internal flashLoan;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Unit_Test.setUp();

        // Cast the linear contract as {SablierV2FlashLoan}.
        flashLoan = SablierV2FlashLoan(address(linear));

        // Set the default flash fee in the comptroller.
        comptroller.setFlashFee({ newFlashFee: DEFAULT_FLASH_FEE });
    }
}
