// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { CreateTest } from "../CreateTest.t.sol";

/// @dev A token with a large total supply.
contract SHIBA__Test is CreateTest {
    function setUp() public override {
        super.setUp();

        approveSablierV2();
    }

    /// @dev random SHIBA holder
    function holder() internal pure override returns (address) {
        return 0x73AF3bcf944a6559933396c1577B257e2054D935;
    }

    function token() internal pure override returns (IERC20) {
        return IERC20(0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE);
    }
}
