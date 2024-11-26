// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Base_Test } from "./../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;
    address internal immutable FORK_TOKEN_HOLDER;
    uint256 internal initialHolderBalance;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken, address forkTokenHolder) {
        FORK_TOKEN = forkToken;
        FORK_TOKEN_HOLDER = forkTokenHolder;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 20_428_723, urlOrAlias: "mainnet" });

        // The base is set up after the fork is selected so that the base test contracts are deployed on the fork.
        Base_Test.setUp();

        // Label the contracts.
        labelContracts();

        // Make the forked token holder the caller in this test suite.
        resetPrank({ msgSender: FORK_TOKEN_HOLDER });

        // Query the initial balance of the forked token holder.
        initialHolderBalance = FORK_TOKEN.balanceOf(FORK_TOKEN_HOLDER);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address sender, address recipient, address broker, address lockupContract) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(sender != address(0) && recipient != address(0) && broker != address(0));

        // The goal is to not have overlapping users because the forked token balance tests would fail otherwise.
        vm.assume(sender != recipient && sender != broker && recipient != broker);
        vm.assume(sender != FORK_TOKEN_HOLDER && recipient != FORK_TOKEN_HOLDER && broker != FORK_TOKEN_HOLDER);
        vm.assume(sender != lockupContract && recipient != lockupContract && broker != lockupContract);

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_TOKEN), sender);
        assumeNoBlacklisted(address(FORK_TOKEN), recipient);
        assumeNoBlacklisted(address(FORK_TOKEN), broker);
    }

    /// @dev Labels the most relevant contracts.
    function labelContracts() internal {
        vm.label({ account: address(FORK_TOKEN), newLabel: IERC20Metadata(address(FORK_TOKEN)).symbol() });
        vm.label({ account: FORK_TOKEN_HOLDER, newLabel: "FORK_TOKEN_HOLDER" });
    }
}
