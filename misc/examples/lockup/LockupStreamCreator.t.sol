// SPDX-License-Identifier: GPL-3-0-or-later
pragma solidity >=0.8.22;

import { Test } from "forge-std/src/Test.sol";

import { LockupDynamicStreamCreator } from "./LockupDynamicStreamCreator.sol";
import { LockupLinearStreamCreator } from "./LockupLinearStreamCreator.sol";
import { LockupTranchedStreamCreator } from "./LockupTranchedStreamCreator.sol";

contract LockupStreamCreatorTest is Test {
    // Test contracts
    LockupDynamicStreamCreator internal dynamicCreator;
    LockupLinearStreamCreator internal linearCreator;
    LockupTranchedStreamCreator internal tranchedCreator;

    address internal user;

    function setUp() public {
        // Fork Ethereum Mainnet
        vm.createSelectFork("ethereum");

        // Deploy the stream creators
        dynamicCreator = new LockupDynamicStreamCreator();
        linearCreator = new LockupLinearStreamCreator();
        tranchedCreator = new LockupTranchedStreamCreator();

        // Create a test user
        user = payable(makeAddr("User"));
        vm.deal({ account: user, newBalance: 1 ether });

        // Mint some DAI tokens to the test user, which will be pulled by the creator contracts
        deal({ token: address(linearCreator.DAI()), to: user, give: 3 * 1337e18 });

        // Make the test user the `msg.sender` in all following calls
        vm.startPrank({ msgSender: user });

        // Approve the creator contracts to pull DAI tokens from the test user
        linearCreator.DAI().approve({ spender: address(dynamicCreator), value: 1337e18 });
        linearCreator.DAI().approve({ spender: address(linearCreator), value: 1337e18 });
        linearCreator.DAI().approve({ spender: address(tranchedCreator), value: 1337e18 });
    }

    // Tests that creating streams works by checking the stream ids
    function test_LockupDynamicStreamCreator() public {
        uint128 amount0 = 1337e18 / 2;
        uint128 amount1 = 1337e18 - amount0;

        uint256 expectedStreamId = dynamicCreator.LOCKUP().nextStreamId();
        uint256 actualStreamId = dynamicCreator.createStream(amount0, amount1);
        assertEq(actualStreamId, expectedStreamId);
    }

    // Tests that creating streams works by checking the stream ids
    function test_LockupLinearStreamCreator() public {
        uint256 expectedStreamId = linearCreator.LOCKUP().nextStreamId();
        uint256 actualStreamId = linearCreator.createStream({ depositAmount: 1337e18 });
        assertEq(actualStreamId, expectedStreamId);
    }

    // Tests that creating streams works by checking the stream ids
    function test_LockupTranchedStreamCreator() public {
        uint128 amount0 = 1337e18 / 2;
        uint128 amount1 = 1337e18 - amount0;

        uint256 expectedStreamId = tranchedCreator.LOCKUP().nextStreamId();
        uint256 actualStreamId = tranchedCreator.createStream(amount0, amount1);
        assertEq(actualStreamId, expectedStreamId);
    }
}
