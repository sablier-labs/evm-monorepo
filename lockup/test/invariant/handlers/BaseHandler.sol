// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { Vm } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { Constants } from "../../utils/Constants.sol";
import { Fuzzers } from "../../utils/Fuzzers.sol";
import { TimestampStore } from "../stores/TimestampStore.sol";

/// @title BaseHandler
/// @notice Base contract with common logic needed by all handler contracts.
abstract contract BaseHandler is Constants, Fuzzers, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maximum number of streams that can be created during an invariant campaign.
    uint256 internal constant MAX_STREAM_COUNT = 100;

    /// @dev The virtual address of the Foundry VM.
    address internal constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256 calls) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Default ERC-20 asset used for testing.
    IERC20 public asset;

    /// @dev Reference to the timestamp store, which is needed for simulating the passage of time.
    TimestampStore public timestampStore;

    /// @dev An instance of the Foundry VM, which contains cheatcodes for testing.
    Vm internal constant vm = Vm(VM_ADDRESS);

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, TimestampStore timestampStore_) {
        asset = asset_;
        timestampStore = timestampStore_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier checkUsers(address sender, address recipient, address broker) {
        // The protocol doesn't allow the sender, recipient or broker to be the zero address.
        if (sender == address(0) || recipient == address(0) || broker == address(0)) {
            return;
        }

        // Prevent the contract itself from playing the role of any user.
        if (sender == address(this) || recipient == address(this) || broker == address(this)) {
            return;
        }

        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory functionName) {
        calls[functionName]++;
        totalCalls++;
        _;
    }

    modifier useCurrentTimestamp() {
        vm.warp(timestampStore.currentTimestamp());
        _;
    }

    /// @dev Makes the provided sender the caller.
    modifier useNewSender(address sender) {
        vm.startPrank(sender);
        _;
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper for simulating the passage of time, which is a pre-requisite for making withdrawals. Each time warp
    /// is upper bounded so that streams don't settle too quickly.
    function increaseCurrentTimestamp(uint256 timeWarp) external instrument("increaseCurrentTimestamp") {
        timeWarp = _bound(timeWarp, 2 hours, 7 days);
        timestampStore.increaseCurrentTimestamp(timeWarp);
    }
}
