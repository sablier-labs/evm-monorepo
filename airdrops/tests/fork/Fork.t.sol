// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Base_Test } from "../Base.t.sol";

/// @notice Common logic needed by all fork tests.
abstract contract Fork_Test is Base_Test {
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
        // TODO: Uncomment the following after deployment.
        // vm.createSelectFork({ blockNumber: 21_719_244, urlOrAlias: "mainnet" });

        // TODO: Uncomment and load deployed addresses from Ethereum mainnet.
        // merkleFactoryInstant = ISablierMerkleFactoryInstant(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);
        // merkleFactoryLL = ISablierMerkleFactoryLL(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);
        // merkleFactoryLT = ISablierMerkleFactoryLT(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);
        // merkleFactoryVCA = ISablierMerkleFactoryVCA(0x71DD3Ca88E7564416E5C2E350090C12Bf8F6144a);
        // lockup = ISablierLockup(0x7C01AA3783577E15fD7e272443D44B92d5b21056);

        // TODO: Remove the following two lines after deployment.
        Base_Test.setUp();
        vm.etch(address(FORK_TOKEN), address(usdc).code);
    }
}
