// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Merkle } from "murky/src/Merkle.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test, Merkle {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) {
        FORK_TOKEN = forkToken;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 21_745_237, urlOrAlias: "mainnet" });

        // Set up the parent test contract.
        Base_Test.setUp();

        // Load the pre-deployed external dependencies.
        lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);
    }
}
