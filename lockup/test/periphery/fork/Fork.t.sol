// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockupDynamic } from "src/core/interfaces/ISablierLockupDynamic.sol";
import { ISablierLockupLinear } from "src/core/interfaces/ISablierLockupLinear.sol";
import { ISablierLockupTranched } from "src/core/interfaces/ISablierLockupTranched.sol";
import { Merkle } from "./../../utils/Murky.sol";
import { Periphery_Test } from "./../Periphery.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Periphery_Test, Merkle {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_ASSET;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkAsset) {
        FORK_ASSET = forkAsset;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 20_339_512, urlOrAlias: "mainnet" });

        // Set up the parent test contract.
        Periphery_Test.setUp();

        // Load the external dependencies.
        loadDependencies();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks the user assumptions.
    function checkUsers(address user, address recipient) internal virtual {
        // The protocol does not allow the zero address to interact with it.
        vm.assume(user != address(0) && recipient != address(0));

        // The goal is to not have overlapping users because the asset balance tests would fail otherwise.
        vm.assume(user != recipient);
        vm.assume(user != address(lockupDynamic) && recipient != address(lockupDynamic));
        vm.assume(user != address(lockupLinear) && recipient != address(lockupLinear));
        vm.assume(user != address(lockupTranched) && recipient != address(lockupTranched));

        // Avoid users blacklisted by USDC or USDT.
        assumeNoBlacklisted(address(FORK_ASSET), user);
        assumeNoBlacklisted(address(FORK_ASSET), recipient);
    }

    /// @dev Loads all dependencies pre-deployed on Mainnet.
    // TODO: Update addresses once deployed.
    function loadDependencies() private {
        lockupDynamic = ISablierLockupDynamic(0x9DeaBf7815b42Bf4E9a03EEc35a486fF74ee7459);
        lockupLinear = ISablierLockupLinear(0x3962f6585946823440d274aD7C719B02b49DE51E);
        lockupTranched = ISablierLockupTranched(0xf86B359035208e4529686A1825F2D5BeE38c28A8);
    }
}
