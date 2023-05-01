// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { StdInvariant } from "forge-std/StdInvariant.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";

import { Base_Test } from "../Base.t.sol";
import { ComptrollerHandler } from "./handlers/ComptrollerHandler.t.sol";

/// @title Invariant_Test
/// @notice Base test contract with common logic needed by all invariant test contracts.
abstract contract Invariant_Test is Base_Test, StdInvariant {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ComptrollerHandler internal comptrollerHandler;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Deploy the entire protocol.
        deployProtocolConditionally();

        // Deploy the comptroller handler.
        comptrollerHandler = new ComptrollerHandler({ asset_: DEFAULT_ASSET, comptroller_: comptroller });
        vm.prank({ msgSender: users.admin });
        comptroller.transferAdmin(address(comptrollerHandler));

        // Target only the comptroller handler for invariant testing (to avoid getting reverts).
        targetContract(address(comptrollerHandler));

        // Exclude the comptroller, linear and dynamic from being `msg.sender`.
        excludeSender(address(comptroller));
        excludeSender(address(linear));
        excludeSender(address(dynamic));

        // Exclude the comptroller handler from being `msg.sender`.
        excludeSender(address(comptrollerHandler));

        // Label the comptroller handler.
        vm.label({ account: address(comptrollerHandler), newLabel: "ComptrollerHandler" });
    }
}
