// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Merkle } from "./../../utils/Murky.sol";
import { Periphery_Test } from "./../Periphery.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Periphery_Test, Merkle {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_ASSET;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkAsset) {
        FORK_ASSET = forkAsset;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 20_428_723, urlOrAlias: "mainnet" });

        // Set up the parent test contract.
        Periphery_Test.setUp();

        // Load the pre-deployed external dependencies.
        // TODO: Update addresses once deployed.
        // lockup = ISablierLockup(0x6Fe81F4Bf1aF1b829f0E701647808f3Aa4b0BdE7);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address user, address recipient) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(user != address(0) && recipient != address(0));

        // The goal is to not have overlapping users because the asset balance tests would fail otherwise.
        vm.assume(user != recipient);
        vm.assume(user != address(lockup) && recipient != address(lockup));

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_ASSET), user);
        assumeNoBlacklisted(address(FORK_ASSET), recipient);
    }
}
