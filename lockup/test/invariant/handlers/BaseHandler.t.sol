// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { Vm } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Calculations } from "../../shared/helpers/Calculations.t.sol";
import { Constants } from "../../shared/helpers/Constants.t.sol";

/// @title BaseHandler
/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Calculations, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev The address of the HEVM contract.
    address internal constant HEVM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev An instance of the HEVM.
    Vm internal constant vm = Vm(HEVM_ADDRESS);

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256) public calls;

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
