// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { CreateTest } from "../CreateTest.t.sol";

/// @dev A token with a large total supply.
contract SHIB__Test is CreateTest {
    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        approveSablierV2();
    }

    /// @dev random SHIB holder
    function holder() internal pure override returns (address) {
        return 0x73AF3bcf944a6559933396c1577B257e2054D935;
    }

    function token() internal pure override returns (address) {
        return 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
    }
}
