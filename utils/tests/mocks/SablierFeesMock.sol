// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { SablierFees } from "src/SablierFees.sol";

contract SablierFeesMock is SablierFees {
    constructor(address initialAdmin) SablierFees(initialAdmin) { }
}
