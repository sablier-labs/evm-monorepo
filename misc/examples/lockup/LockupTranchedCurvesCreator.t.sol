// SPDX-License-Identifier: GPL-3-0-or-later
pragma solidity >=0.8.22;

import { Test } from "forge-std/src/Test.sol";

import { LockupTranchedCurvesCreator } from "./LockupTranchedCurvesCreator.sol";

contract LockupTranchedCurvesCreatorTest is Test {
    // Test contracts
    LockupTranchedCurvesCreator internal creator;

    address internal user;

    function setUp() public {
        // Fork Ethereum Mainnet
        vm.createSelectFork("mainnet");

        // Deploy the stream creator
        creator = new LockupTranchedCurvesCreator();

        // Create a test user
        user = payable(makeAddr("User"));
        vm.deal({ account: user, newBalance: 1 ether });

        // Mint some DAI tokens to the test user, which will be pulled by the creator contract
        deal({ token: address(creator.DAI()), to: user, give: 1337e18 });

        // Make the test user the `msg.sender` in all following calls
        vm.startPrank({ msgSender: user });

        // Approve the creator contract to pull DAI tokens from the test user
        creator.DAI().approve({ spender: address(creator), value: 1337e18 });
    }

    function test_CreateStream_UnlockInSteps() public {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_UnlockInSteps();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 actualStreamedAmount;
        uint256 expectedStreamedAmount;

        for (uint256 i = 0; i < 4; ++i) {
            vm.warp({ newTimestamp: block.timestamp + 25 days - 1 seconds });
            actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
            assertEq(actualStreamedAmount, expectedStreamedAmount);
            expectedStreamedAmount += 25e18;
            vm.warp({ newTimestamp: block.timestamp + 1 seconds });
        }
    }

    function test_CreateStream_MonthlyUnlocks() public {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_MonthlyUnlocks();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 actualStreamedAmount;
        uint256 expectedStreamedAmount;

        for (uint256 i = 0; i < 12; ++i) {
            vm.warp({ newTimestamp: block.timestamp + 30 days - 1 seconds });
            actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);

            assertEq(actualStreamedAmount, expectedStreamedAmount);
            expectedStreamedAmount += 10e18;
            vm.warp({ newTimestamp: block.timestamp + 1 seconds });
        }
    }

    function test_CreateStream_Timelock() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_Timelock();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 blockTimestamp = block.timestamp;

        // Warp 90 days - 1 second into the future, i.e. exactly 1 second before unlock.
        vm.warp({ newTimestamp: blockTimestamp + 90 days - 1 seconds });

        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount);

        // Warp 90 days into the future, i.e. the unlock moment.
        vm.warp({ newTimestamp: blockTimestamp + 90 days });

        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 100e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount);
    }
}
