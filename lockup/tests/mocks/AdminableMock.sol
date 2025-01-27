// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Adminable } from "src/abstracts/Adminable.sol";

contract AdminableMock is Adminable {
    constructor(address initialAdmin) Adminable(initialAdmin) { }
}
