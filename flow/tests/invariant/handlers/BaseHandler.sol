// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Utils } from "../../utils/Utils.sol";
import { FlowStore } from "../stores/FlowStore.sol";

/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is StdCheats, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum number of streams that can be created.
    uint256 internal constant MAX_STREAM_COUNT = 10_000;

    /// @dev Maps function names and the number of times they have been called by the stream ID.
    mapping(uint256 streamId => mapping(string func => uint256 calls)) public calls;

    /// @dev The current token being used in the handler.
    IERC20 public currentToken;

    /// @dev The total number of calls made to a specific function.
    mapping(string func => uint256 calls) public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ISablierComptroller public comptroller;
    ISablierFlow public flow;
    FlowStore public flowStore;

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Simulates the passage of time. The time jump is kept under 40 days to prevent the streamed amount
    /// from becoming excessively large.
    /// @param timeJump A fuzzed value for time warps.
    modifier adjustTimestamp(uint256 timeJump) {
        timeJump = bound(timeJump, 0, 40 days);
        skip(timeJump);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(uint256 streamId, string memory functionName) {
        if (streamId > 0) {
            calls[streamId][functionName]++;
        }
        totalCalls[functionName]++;
        _;
    }

    modifier useFuzzedToken(uint256 tokenIndex) {
        IERC20[] memory tokens = flowStore.getTokens();
        tokenIndex = bound(tokenIndex, 0, tokens.length - 1);
        currentToken = tokens[tokenIndex];
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(FlowStore flowStore_, ISablierFlow flow_) {
        comptroller = flow_.comptroller();
        flowStore = flowStore_;
        flow = flow_;
    }
}
