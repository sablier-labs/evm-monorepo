// SPDX-License-Identifier: GPL-3-0-or-later
pragma solidity >=0.8.22;

import { Test } from "forge-std/src/Test.sol";

import { LockupLinearCurvesCreator } from "./LockupLinearCurvesCreator.sol";

contract LockupLinearCurvesCreatorTest is Test {
    // Test contracts
    LockupLinearCurvesCreator internal creator;

    address internal user;

    function setUp() public {
        // Fork Ethereum Mainnet
        vm.createSelectFork("mainnet");

        // Deploy the stream creator
        creator = new LockupLinearCurvesCreator();

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

    function test_CreateStream_Linear() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_Linear();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId, "streamId");

        uint256 blockTimestamp = block.timestamp;

        // Assert that the amount is zero at start.
        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount);

        // Warp 20 days into the future.
        vm.warp({ newTimestamp: blockTimestamp + 20 days });

        // Assert that the streamed amount has linearly increased.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 20e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount);

        // Warp 50 days into the future.
        vm.warp({ newTimestamp: blockTimestamp + 50 days });

        // Assert that the streamed amount has linearly increased.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 50e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount);
    }

    function test_CreateStream_CliffUnlock() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_CliffUnlock();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 blockTimestamp = block.timestamp;

        // Warp a second before the cliff.
        vm.warp({ newTimestamp: blockTimestamp + 25 days - 1 seconds });

        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount);

        // Warp to the cliff time.
        vm.warp({ newTimestamp: blockTimestamp + 25 days });

        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 25e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "cliff unlock amount");

        // Warp to the halfway point of the stream duration.
        vm.warp({ newTimestamp: blockTimestamp + 50 days });

        // Assert that the streamed amount has linearly increased.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 50e18;
        assertApproxEqAbs(actualStreamedAmount, expectedStreamedAmount, 100, "cliff unlock amount + linear streaming");
    }

    function test_CreateStream_InitialUnlock() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_InitialUnlock();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 blockTimestamp = block.timestamp;

        // Warp 1 second into the future, i.e. the initial unlock.
        vm.warp({ newTimestamp: blockTimestamp });

        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 25e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount);

        // Warp to the halfway point of the stream duration.
        vm.warp({ newTimestamp: blockTimestamp + 50 days });

        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 62.5e18; // 0.50 * 75 + 25
        assertEq(actualStreamedAmount, expectedStreamedAmount);
    }

    function test_CreateStream_InitialCliffUnlock() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_InitialCliffUnlock();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 blockTimestamp = block.timestamp;

        // Assert that the streamed amount is the initial unlock amount.
        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 25e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "initial unlock");

        // Warp 1 second before the cliff time.
        vm.warp({ newTimestamp: blockTimestamp + 50 days - 1 });

        // Assert that the streamed amount has remained the same.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "1 second before cliff");

        // Warp to the cliff time.
        vm.warp({ newTimestamp: blockTimestamp + 50 days });

        // Assert that the streamed amount has unlocked the cliff amount.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 50e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "cliff unlock amount");

        // Warp 75 days into the future.
        vm.warp({ newTimestamp: blockTimestamp + 75 days });

        // Assert that the streamed amount has increased linearly after cliff.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 75e18;
        assertApproxEqAbs(actualStreamedAmount, expectedStreamedAmount, 100, "linear streaming after cliff");
    }

    function test_CreateStream_ConstantCliff() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_ConstantCliff();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 blockTimestamp = block.timestamp;

        // Warp 1 second into the future.
        vm.warp({ newTimestamp: blockTimestamp + 1 seconds });

        // Assert that the streamed amount is zero.
        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "not zero");

        // Warp 1 second before the cliff time.
        vm.warp({ newTimestamp: blockTimestamp + 25 days - 1 });

        // Assert that the streamed amount has remained the same.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "1 second before cliff");

        // Warp to 62.5 days into the future.
        vm.warp({ newTimestamp: blockTimestamp + 62.5 days });

        // Assert that the streamed amount has linearly increased.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 50e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "linear streaming");
    }

    function test_CreateStream_InitialUnlockConstantCliff() external {
        uint256 expectedStreamId = creator.LOCKUP().nextStreamId();
        uint256 actualStreamId = creator.createStream_InitialUnlockConstantCliff();

        // Assert that the stream has been created.
        assertEq(actualStreamId, expectedStreamId);

        uint256 blockTimestamp = block.timestamp;

        // Assert that the streamed amount is zero.
        uint128 actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        uint128 expectedStreamedAmount = 25e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "initial unlock");

        // Warp 1 second before the cliff time.
        vm.warp({ newTimestamp: blockTimestamp + 25 days - 1 });

        // Assert that the streamed amount has remained the same.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "1 second before cliff");

        // Warp to 75 days into the future.
        vm.warp({ newTimestamp: blockTimestamp + 62.5 days });

        // Assert that the streamed amount has linearly increased.
        actualStreamedAmount = creator.LOCKUP().streamedAmountOf(actualStreamId);
        expectedStreamedAmount = 62.5e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "linear streaming");
    }
}
