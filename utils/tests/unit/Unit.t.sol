// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { CommonBase } from "../Base.t.sol";
import { ContractWithoutReceive, ContractWithReceive } from "../mocks/Receive.sol";

abstract contract Unit_Test is CommonBase {
    address internal admin;
    address internal eve;

    ContractWithoutReceive internal contractWithoutReceive;
    ContractWithReceive internal contractWithReceive;

    function setUp() public virtual override {
        CommonBase.setUp();

        admin = createUser("admin");
        eve = createUser("eve");
        contractWithoutReceive = new ContractWithoutReceive();
        contractWithReceive = new ContractWithReceive();

        resetPrank(admin);
    }
}
