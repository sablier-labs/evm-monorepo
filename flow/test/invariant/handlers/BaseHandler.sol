// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Utils } from "../../utils/Utils.sol";
import { FlowStore } from "../stores/FlowStore.sol";

/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is StdCheats, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum number of streams that can be created during an invariant campaign.
    uint256 internal constant MAX_STREAM_COUNT = 100;

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256 calls) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierFlow public flow;
    FlowStore public flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(FlowStore flowStore_, ISablierFlow flow_) {
        flowStore = flowStore_;
        flow = flow_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Simulates the passage of time. The time jump is upper bounded so that streams don't settle too quickly.
    /// @param timeJumpSeed A fuzzed value needed for generating random time warps.
    modifier adjustTimestamp(uint256 timeJumpSeed) {
        uint256 timeJump = _bound(timeJumpSeed, 2 minutes, 40 days);
        vm.warp(getBlockTimestamp() + timeJump);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        calls[functionName]++;
        totalCalls++;
        _;
    }
}
