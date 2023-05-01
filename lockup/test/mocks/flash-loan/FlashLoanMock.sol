// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { SablierV2Base } from "../../../src/abstracts/SablierV2Base.sol";
import { ISablierV2Comptroller } from "../../../src/interfaces/ISablierV2Comptroller.sol";
import { SablierV2FlashLoan } from "../../../src/abstracts/SablierV2FlashLoan.sol";

/// @dev Needed to test the {SablierV2FlashLoan} abstract.
contract FlashLoanMock is SablierV2FlashLoan {
    constructor(
        address initialAdmin,
        ISablierV2Comptroller initialComptroller
    )
        SablierV2Base(initialAdmin, initialComptroller)
    { }
}
