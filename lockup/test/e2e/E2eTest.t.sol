// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { Base_Test } from "../Base.t.sol";

/// @title E2e_Test
/// @notice Collections of tests that run against a fork of Ethereum Mainnet.
abstract contract E2e_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable asset;
    address internal immutable holder;

    /*//////////////////////////////////////////////////////////////////////////
                                    TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    uint256 internal initialHolderBalance;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 asset_, address holder_) {
        asset = asset_;
        holder = holder_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // Fork Ethereum Mainnet.
        vm.createSelectFork({ urlOrAlias: "ethereum", blockNumber: 16_126_000 });

        // Deploy the entire protocol.
        deployProtocol();

        // Make the asset holder the caller in this test suite.
        vm.startPrank(holder);

        // Query the initial balance of the asset holder.
        initialHolderBalance = asset.balanceOf(holder);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address broker, address protocolContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // The goal is to not have overlapping users because the token balance tests would fail otherwise.
        vm.assume(sender != recipient && sender != broker && recipient != broker);
        vm.assume(sender != holder && recipient != holder && broker != holder);
        vm.assume(sender != protocolContract && recipient != protocolContract && broker != protocolContract);
    }
}
