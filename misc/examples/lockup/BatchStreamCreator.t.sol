// SPDX-License-Identifier: GPL-3-0-or-later
pragma solidity >=0.8.22;

import { Test } from "forge-std/src/Test.sol";

import { BatchLDStreamCreator } from "./BatchLDStreamCreator.sol";
import { BatchLLStreamCreator } from "./BatchLLStreamCreator.sol";
import { BatchLTStreamCreator } from "./BatchLTStreamCreator.sol";

contract BatchStreamCreatorTest is Test {
    // Test contracts
    BatchLDStreamCreator internal dynamicCreator;
    BatchLLStreamCreator internal linearCreator;
    BatchLTStreamCreator internal tranchedCreator;

    address internal user;

    function setUp() public {
        // Fork Ethereum Mainnet
        vm.createSelectFork("mainnet");

        // Deploy the stream creators
        dynamicCreator = new BatchLDStreamCreator();
        linearCreator = new BatchLLStreamCreator();
        tranchedCreator = new BatchLTStreamCreator();

        // Create a test user
        user = payable(makeAddr("User"));
        vm.deal({ account: user, newBalance: 1 ether });

        // Mint some DAI tokens to the test user, which will be pulled by the creator contracts
        deal({ token: address(linearCreator.DAI()), to: user, give: 6 * 1337e18 });

        // Make the test user the `msg.sender` in all following calls
        vm.startPrank({ msgSender: user });

        // Approve the creator contracts to pull DAI tokens from the test user
        dynamicCreator.DAI().approve({ spender: address(dynamicCreator), value: 2 * 1337e18 });
        linearCreator.DAI().approve({ spender: address(linearCreator), value: 2 * 1337e18 });
        tranchedCreator.DAI().approve({ spender: address(tranchedCreator), value: 2 * 1337e18 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    // Tests that creating streams works by checking the stream ids
    function test_BatchLockupDynamicStreamCreator() public {
        uint256 nextStreamId = dynamicCreator.LOCKUP().nextStreamId();
        uint256[] memory actualStreamIds = dynamicCreator.batchCreateStreams({ perStreamAmount: 1337e18 });
        uint256[] memory expectedStreamIds = new uint256[](2);
        expectedStreamIds[0] = nextStreamId;
        expectedStreamIds[1] = nextStreamId + 1;
        assertEq(actualStreamIds, expectedStreamIds);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    // Tests that creating streams works by checking the stream ids
    function test_BatchLockupLinearStreamCreator() public {
        uint256 nextStreamId = linearCreator.LOCKUP().nextStreamId();
        uint256[] memory actualStreamIds = linearCreator.batchCreateStreams({ perStreamAmount: 1337e18 });
        uint256[] memory expectedStreamIds = new uint256[](2);
        expectedStreamIds[0] = nextStreamId;
        expectedStreamIds[1] = nextStreamId + 1;
        assertEq(actualStreamIds, expectedStreamIds);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    // Tests that creating streams works by checking the stream ids
    function test_BatchLockupTranchedStreamCreator() public {
        uint256 nextStreamId = tranchedCreator.LOCKUP().nextStreamId();
        uint256[] memory actualStreamIds = tranchedCreator.batchCreateStreams({ perStreamAmount: 1337e18 });
        uint256[] memory expectedStreamIds = new uint256[](2);
        expectedStreamIds[0] = nextStreamId;
        expectedStreamIds[1] = nextStreamId + 1;
        assertEq(actualStreamIds, expectedStreamIds);
    }
}
