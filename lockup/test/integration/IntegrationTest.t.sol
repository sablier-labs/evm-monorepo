// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { SablierV2Comptroller } from "src/SablierV2Comptroller.sol";
import { SablierV2Linear } from "src/SablierV2Linear.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "test/BaseTest.t.sol";
import { IMulticall3 } from "test/helpers/IMulticall3.t.sol";

/// @title IntegrationTest
/// @notice Collections of tests run against an Ethereum Mainnet fork.
abstract contract IntegrationTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    address internal holder;
    uint256 internal initialHolderBalance;
    IERC20 internal token;

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IMulticall3 internal multicall;

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

    function setUp() public virtual override {
        BaseTest.setUp();

        // Fork Ethereum Mainnet.
        vm.createSelectFork({ urlOrAlias: vm.envString("ETH_RPC_URL"), blockNumber: 16_126_000 });

        // Deploy all Sablier contracts.
        deploySablierContracts();

        // Load the Multicall3 contract at the deterministic deployment address.
        multicall = IMulticall3(MULTICALL3_ADDRESS);

        // Make the token holder the caller in this test suite.
        changePrank(holder);

        // Query the initial holder's balance.
        initialHolderBalance = IERC20(token).balanceOf(holder);
    }

    event LogBytesArray(bytes[] arr);

    /// @dev Performs a single call with Multicall3 to query the ERC-20 token balances of the given addresses.
    function getTokenBalances(address[] memory addresses) internal returns (uint256[] memory balances) {
        // ABI encode the aggregate call to Multicall3.
        uint256 length = addresses.length;
        IMulticall3.Call[] memory calls = new IMulticall3.Call[](length);
        for (uint256 i = 0; i < length; ++i) {
            calls[i] = IMulticall3.Call({
                target: address(token),
                callData: abi.encodeCall(IERC20.balanceOf, (addresses[i]))
            });
        }

        // Make the aggregate call.
        (, bytes[] memory returnData) = multicall.aggregate(calls);

        // ABI decode the return data and return the balances.
        balances = new uint256[](length);
        for (uint256 i = 0; i < length; ++i) {
            balances[i] = abi.decode(returnData[i], (uint256));
        }
    }
}
