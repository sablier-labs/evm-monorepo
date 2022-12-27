// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "../BaseTest.t.sol";

/// @title IntegrationTest
/// @notice Collections of tests run against an Ethereum Mainnet fork.
abstract contract IntegrationTest is BaseTest {
    function setUp() public virtual override {
        super.setUp();
        vm.createSelectFork({ urlOrAlias: vm.envString("ETH_RPC_URL"), blockNumber: 16_126_000 });
    }
}
