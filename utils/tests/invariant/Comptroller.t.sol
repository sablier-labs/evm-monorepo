// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.26;

import { StdInvariant } from "forge-std/src/StdInvariant.sol";
import { ComptrollerHandler } from "./handlers/ComptrollerHandler.sol";

import { Base_Test } from "../Base.t.sol";

contract Comptroller_Invariant_Test is Base_Test, StdInvariant {
    ComptrollerHandler public comptrollerHandler;

    address public implAddress;

    /*//////////////////////////////////////////////////////////////////////////
                                       SET UP
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Base_Test.setUp();

        // Deploy the comptroller handler.
        comptrollerHandler = new ComptrollerHandler(address(comptroller));

        // Assign the implementation address.
        implAddress = getComptrollerImplAddress();

        // Label the comptroller handler.
        vm.label({ account: address(comptrollerHandler), newLabel: "comptrollerHandler" });

        // Set the target contract.
        targetContract(address(comptrollerHandler));

        // Prevent the admin from being fuzzed as `msg.sender`.
        excludeSender(admin);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HANDLERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The invariant should not be able to change admin.
    function invariant_Admin() external view {
        assertEq(comptroller.admin(), admin, "Invariant violation: admin changed");
    }

    /// @dev The invariant should not be able to change the oracle.
    function invariant_Oracle() external view {
        assertEq(comptroller.oracle(), address(oracle), "Invariant violation: oracle changed");
    }

    /// @dev The invariant should not be able to change the implementation.
    function invariant_Implementation() external view {
        assertEq(getComptrollerImplAddress(), implAddress, "Invariant violation: implementation changed");
    }

    /// @dev The invariant should not be able to call any function on the comptroller.
    function invariant_FunctionSuccess() external view {
        assertEq(comptrollerHandler.calls("initialize"), 0, "Invariant violation: initialize called");
        assertEq(comptrollerHandler.calls("transferAdmin"), 0, "Invariant violation: transferAdmin called");
        assertEq(comptrollerHandler.calls("upgradeToAndCall"), 0, "Invariant violation: upgradeToAndCall called");
    }
}
