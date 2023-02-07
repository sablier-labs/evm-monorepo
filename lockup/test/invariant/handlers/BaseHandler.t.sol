// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { StdCheats } from "forge-std/StdCheats.sol";
import { Vm } from "@prb/test/Vm.sol";

import { Calculations } from "../../shared/helpers/Calculations.t.sol";
import { Constants } from "../../shared/helpers/Constants.t.sol";
import { Utils } from "../../shared/helpers/Utils.t.sol";

import { Base_Test } from "../../Base.t.sol";

/// @title BaseHandler
/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps function names to the number of times they have been called.
    mapping(string => uint256) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                        MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory func) {
        calls[func]++;
        totalCalls++;
        _;
    }
}
