// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { CreateTest } from "../CreateTest.t.sol";

/// @dev A typical 18-decimal token with a normal total supply.
contract DAI__Test is CreateTest {
    function setUp() public override {
        super.setUp();

        approveSablierV2();
    }

    /// @dev random DAI holder
    function holder() internal pure override returns (address) {
        return 0x66F62574ab04989737228D18C3624f7FC1edAe14;
    }

    function token() internal pure override returns (address) {
        return 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }
}
