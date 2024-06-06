// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { FlowStore } from "../stores/FlowStore.sol";
import { Constants } from "../../utils/Constants.sol";
import { Utils } from "../../utils/Utils.sol";

/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Constants, StdCheats, Utils {
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

    /*//////////////////////////////////////////////////////////////////////////
                                       HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to calculate the upper bound, based on the asset decimals, for the transfer amount.
    function getTransferAmountUpperBound(uint8 assetDecimals) internal pure returns (uint128 upperBound) {
        if (assetDecimals == 0) {
            upperBound = 1_000_000;
        } else if (assetDecimals == 6) {
            upperBound = 1_000_000e6;
        } else {
            upperBound = 1_000_000e18;
        }
    }
}
