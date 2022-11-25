// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "src/interfaces/ISablierV2.sol";
import { SablierV2 } from "src/SablierV2.sol";

import { AbstractSablierV2 } from "./AbstractSablierV2.t.sol";
import { IntegrationTest } from "../IntegrationTest.t.sol";

/// @title AbstractSablierV2Test
/// @notice Common contract members needed across Sablier V2 test contracts.
/// @dev Strictly for test purposes.
abstract contract AbstractSablierV2Test is IntegrationTest {
    AbstractSablierV2 internal abstractSablierV2 = new AbstractSablierV2();

    /// @dev A setup function invoked before each test case.
    function setUp() public virtual {
        // Sets all subsequent calls' `msg.sender` to be `sender`.
        vm.startPrank(users.sender);
    }
}
