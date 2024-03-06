// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdInvariant } from "forge-std/src/StdInvariant.sol";

import { Base_Test } from "../Base.t.sol";
import { ComptrollerHandler } from "./handlers/ComptrollerHandler.sol";
import { TimestampStore } from "./stores/TimestampStore.sol";

/// @notice Common logic needed by all invariant tests.
abstract contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ComptrollerHandler internal comptrollerHandler;
    TimestampStore internal timestampStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier useCurrentTimestamp() {
        vm.warp(timestampStore.currentTimestamp());
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the handlers.
        timestampStore = new TimestampStore();
        comptrollerHandler =
            new ComptrollerHandler({ asset_: dai, comptroller_: comptroller, timestampStore_: timestampStore });
        changePrank(users.admin);
        comptroller.transferAdmin(address(comptrollerHandler));

        // Label the handlers.
        vm.label({ account: address(comptrollerHandler), newLabel: "ComptrollerHandler" });
        vm.label({ account: address(timestampStore), newLabel: "TimestampStore" });

        // Target only the handlers for invariant testing (to avoid getting reverts).
        targetContract(address(comptrollerHandler));

        // Prevent these contracts from being fuzzed as `msg.sender`.
        excludeSender(address(comptroller));
        excludeSender(address(comptrollerHandler));
        excludeSender(address(lockupDynamic));
        excludeSender(address(lockupLinear));
        excludeSender(address(timestampStore));
    }
}
