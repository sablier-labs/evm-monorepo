// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2LockupDynamic } from "src/SablierV2LockupDynamic.sol";
import { SablierV2LockupLinear } from "src/SablierV2LockupLinear.sol";

import { Base_Test } from "../Base.t.sol";
import { USDCLike } from "../mocks/erc20/USDCLike.sol";
import { USDTLike } from "../mocks/erc20/USDTLike.sol";

/// @title Fork_Test
/// @notice Collections of tests that run against a fork of Ethereum Mainnet.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable asset;
    address internal immutable holder;

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
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
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 16_126_000 });

        // Deploy the entire protocol.
        deployProtocol();

        // Make the asset holder the caller in this test suite.
        vm.startPrank(holder);

        // Query the initial balance of the asset holder.
        initialHolderBalance = asset.balanceOf(holder);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address broker, address sablierContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // The goal is to not have overlapping users because the token balance tests would fail otherwise.
        vm.assume(sender != recipient && sender != broker && recipient != broker);
        vm.assume(sender != holder && recipient != holder && broker != holder);
        vm.assume(sender != sablierContract && recipient != sablierContract && broker != sablierContract);

        // Avoid blacklisted users in USDC and USDT.
        if (address(asset) == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {
            USDCLike usdc = USDCLike(address(asset));
            vm.assume(!usdc.isBlacklisted(sender) && !usdc.isBlacklisted(recipient) && !usdc.isBlacklisted(broker));
        } else if (address(asset) == 0xdAC17F958D2ee523a2206206994597C13D831ec7) {
            USDTLike usdt = USDTLike(address(asset));
            vm.assume(!usdt.isBlackListed(sender) && !usdt.isBlackListed(recipient) && !usdt.isBlackListed(broker));
        }
    }
}
