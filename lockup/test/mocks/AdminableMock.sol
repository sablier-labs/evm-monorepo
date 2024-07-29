// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Adminable } from "src/core/abstracts/Adminable.sol";
import { IAdminable } from "src/core/interfaces/IAdminable.sol";

contract AdminableMock is Adminable {
    constructor(address initialAdmin) {
        admin = initialAdmin;
        emit IAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }
}
