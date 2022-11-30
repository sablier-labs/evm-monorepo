// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { CreateTest } from "../CreateTest.t.sol";

/// @dev A token with 6 decimals.
contract USDC__Test is CreateTest {
    function setUp() public override {
        super.setUp();

        approveSablierV2();
    }

    /// @dev random USDC holder
    function holder() internal pure override returns (address) {
        return 0x09528d637deb5857dc059dddE6316D465a8b3b69;
    }

    function token() internal pure override returns (address) {
        return 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    }
}
