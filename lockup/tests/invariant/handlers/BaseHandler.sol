// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StdCheats } from "forge-std/src/StdCheats.sol";
import { ISablierLockup } from "src/interfaces/ISablierLockup.sol";

import { Constants } from "../../utils/Constants.sol";
import { Fuzzers } from "../../utils/Fuzzers.sol";

/// @notice Base contract with common logic needed by {LockupHandler} and {LockupCreateHandler} contracts.
abstract contract BaseHandler is Constants, Fuzzers, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                    STATE-VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum number of streams that can be created during an invariant campaign.
    uint256 internal constant MAX_STREAM_COUNT = 300;

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256 calls) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    ISablierLockup public lockup;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Default ERC-20 token used for testing.
    IERC20 public token;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, ISablierLockup lockup_) {
        token = token_;
        lockup = lockup_;
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

    /// @dev Checks user assumptions.
    modifier checkUsers(address sender, address recipient, address broker) {
        // Prevent the sender, recipient and broker to be the zero address.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // Prevent the contract itself from playing the role of any user.
        vm.assume(sender != address(this) && recipient != address(this) && broker != address(this));
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        calls[functionName]++;
        totalCalls++;
        _;
    }

    /// @dev Makes the provided sender the caller.
    modifier useNewSender(address sender) {
        resetPrank(sender);
        _;
    }
}
