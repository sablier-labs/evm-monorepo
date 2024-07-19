// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_ASSET;
    address internal immutable FORK_ASSET_HOLDER;
    uint256 internal initialHolderBalance;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkAsset, address forkAssetHolder) {
        FORK_ASSET = forkAsset;
        FORK_ASSET_HOLDER = forkAssetHolder;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 19_000_000, urlOrAlias: "mainnet" });

        // The base is set up after the fork is selected so that the base test contracts are deployed on the fork.
        Base_Test.setUp();

        // Label the contracts.
        labelContracts();

        // Make the forked asset holder the caller in this test suite.
        resetPrank({ msgSender: FORK_ASSET_HOLDER });

        // Query the initial balance of the forked asset holder.
        initialHolderBalance = FORK_ASSET.balanceOf(FORK_ASSET_HOLDER);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address broker, address sablierContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // The goal is to not have overlapping users because the forked asset balance tests would fail otherwise.
        vm.assume(sender != recipient && sender != broker && recipient != broker);
        vm.assume(sender != FORK_ASSET_HOLDER && recipient != FORK_ASSET_HOLDER && broker != FORK_ASSET_HOLDER);
        vm.assume(sender != sablierContract && recipient != sablierContract && broker != sablierContract);

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_ASSET), sender);
        assumeNoBlacklisted(address(FORK_ASSET), recipient);
        assumeNoBlacklisted(address(FORK_ASSET), broker);
    }

    /// @dev Labels the most relevant contracts.
    function labelContracts() internal {
        vm.label({ account: address(FORK_ASSET), newLabel: IERC20Metadata(address(FORK_ASSET)).symbol() });
        vm.label({ account: FORK_ASSET_HOLDER, newLabel: "FORK_ASSET_HOLDER" });
    }
}
