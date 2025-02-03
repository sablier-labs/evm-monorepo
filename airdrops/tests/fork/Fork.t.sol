// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISablierLockup } from "@sablier/lockup/src/interfaces/ISablierLockup.sol";
import { Merkle } from "murky/src/Merkle.sol";
import { ISablierMerkleFactory } from "src/interfaces/ISablierMerkleFactory.sol";

import { Base_Test } from "../Base.t.sol";
import { Defaults } from "../utils/Defaults.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test, Merkle {
    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable FORK_TOKEN;
    address internal factoryAdmin;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 forkToken) {
        FORK_TOKEN = forkToken;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Fork Ethereum Mainnet at a specific block number.
        vm.createSelectFork({ blockNumber: 21_719_244, urlOrAlias: "mainnet" });

        // Load deployed addresses from Ethereum mainnet.
        merkleFactory = ISablierMerkleFactory(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);
        lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);

        // Load the factory admin from mainnet.
        factoryAdmin = merkleFactory.admin();

        // Initialize the defaults contract.
        defaults = new Defaults();

        // Set the default fee for campaign.
        resetPrank({ msgSender: factoryAdmin });
        merkleFactory.setDefaultFee(defaults.FEE());
    }
}
