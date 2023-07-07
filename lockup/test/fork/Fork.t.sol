// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
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
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 16_126_000, urlOrAlias: "mainnet" });

        // The base is set up after the fork is selected so that the base test contracts are deployed on the fork.
        Base_Test.setUp();

        // Deploy V2 Core.
        deployCoreConditionally();

        // Label the contracts.
        labelContracts();

        // Make the asset holder the caller in this test suite.
        vm.startPrank({ msgSender: holder });

        // Query the initial balance of the asset holder.
        initialHolderBalance = asset.balanceOf(holder);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address broker, address sablierContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // The goal is to not have overlapping users because the asset balance tests would fail otherwise.
        vm.assume(sender != recipient && sender != broker && recipient != broker);
        vm.assume(sender != holder && recipient != holder && broker != holder);
        vm.assume(sender != sablierContract && recipient != sablierContract && broker != sablierContract);

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(asset), sender);
        assumeNoBlacklisted(address(asset), recipient);
        assumeNoBlacklisted(address(asset), broker);
    }

    /// @dev Labels the most relevant contracts.
    function labelContracts() internal {
        vm.label({ account: address(asset), newLabel: IERC20Metadata(address(asset)).symbol() });
        vm.label({ account: holder, newLabel: "Holder" });
    }
}
