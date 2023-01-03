// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "../BaseTest.t.sol";

/// @title IntegrationTest
/// @notice Collections of tests run against an Ethereum Mainnet fork.
abstract contract IntegrationTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    address internal holder;
    uint256 internal holderBalance;
    IERC20 internal token;

    /*//////////////////////////////////////////////////////////////////////////
                                 SABLIER CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    SablierV2Comptroller internal comptroller;
    SablierV2Linear internal linear;
    SablierV2Pro internal pro;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IERC20 token_, address holder_) {
        token = token_;
        holder = holder_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        vm.createSelectFork({ urlOrAlias: vm.envString("ETH_RPC_URL"), blockNumber: 16_126_000 });

        // Deploy all contracts.
        comptroller = new SablierV2Comptroller();
        linear = new SablierV2Linear({ initialComptroller: comptroller, maxFee: DEFAULT_MAX_FEE });
        pro = new SablierV2Pro({
            initialComptroller: comptroller,
            maxFee: DEFAULT_MAX_FEE,
            maxSegmentCount: DEFAULT_MAX_SEGMENT_COUNT
        });

        // Make the token holder the caller in this test suite.
        vm.startPrank({ msgSender: holder });

        // Query the holder's balance.
        holderBalance = IERC20(token).balanceOf(holder);
    }
}
