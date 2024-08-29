// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Flow } from "src/types/DataTypes.sol";

import { Fork_Test } from "./Fork.t.sol";

contract Flow_Fork_Test is Fork_Test {
    /// @dev Total number of streams to create for each token.
    uint256 internal constant TOTAL_STREAMS = 20;

    /// @dev An enum to represent functions from the Flow contract.
    enum FlowFunc {
        adjustRatePerSecond,
        deposit,
        pause,
        refund,
        restart,
        void,
        withdrawAt
    }

    /// @dev A struct to hold the fuzzed parameters to be used during fork tests.
    struct Params {
        uint256 timeJump;
        // Create params
        address recipient;
        address sender;
        uint128 ratePerSecond;
        bool transferable;
        // Amounts
        uint128 depositAmount;
        uint128 refundAmount;
        uint40 withdrawAtTime;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    FORK TEST
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev For each token:
    /// - It creates the equal number of new streams
    /// - It executes the same sequence of flow functions for each token
    /// @param params The fuzzed parameters to use for the tests.
    /// @param flowFuncU8 Using calldata here as required by array slicing in Solidity, and using `uint8` to be
    /// able to bound it.
    function testForkFuzz_Flow(Params memory params, uint8[] calldata flowFuncU8) public {
        // Ensure a large number of function calls.
        vm.assume(flowFuncU8.length > 1);

        // Limit the number of functions to call if it exceeds 15.
        if (flowFuncU8.length > 15) {
            flowFuncU8 = flowFuncU8[0:15];
        }

        // Prepare a sequence of flow functions to execute.
        FlowFunc[] memory flowFunc = new FlowFunc[](flowFuncU8.length);
        for (uint256 i = 0; i < flowFuncU8.length; ++i) {
            flowFunc[i] = FlowFunc(boundUint8(flowFuncU8[i], 0, 6));
        }

        // Run the tests for each token.
        for (uint256 i = 0; i < tokens.length; ++i) {
            token = tokens[i];
            _executeSequence(params, flowFunc);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                PRIVATE HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev For a given token, it creates a number of streams and then execute the sequence of Flow functions.
    /// @param params The fuzzed parameters to use for the tests.
    /// @param flowFunc The sequence of Flow functions to execute.
    function _executeSequence(Params memory params, FlowFunc[] memory flowFunc) private {
        uint256 initialStreamId = flow.nextStreamId();

        // Create a series of streams at a different period of time.
        for (uint256 i = 0; i < TOTAL_STREAMS; ++i) {
            // Create unique values by hashing the fuzzed params with index.
            params.recipient = makeAddr(vm.toString(abi.encodePacked(params.recipient, i)));
            params.sender = makeAddr(vm.toString(abi.encodePacked(params.sender, i)));
            params.ratePerSecond =
                boundRatePerSecond(uint128(uint256(keccak256(abi.encodePacked(params.ratePerSecond, i)))));

            // Make sure that fuzzed users don't overlap with Flow address.
            checkUsers(params.recipient, params.sender);

            // Warp to a different time.
            params.timeJump = _passTime(params.timeJump);

            // Create a stream.
            _test_Create(params.recipient, params.sender, params.ratePerSecond, params.transferable);
        }

        // Assert that the stream IDs have been bumped.
        uint256 finalStreamId = flow.nextStreamId();
        assertEq(initialStreamId + TOTAL_STREAMS, finalStreamId);

        // Execute the sequence of flow functions as stored in `flowFunc` variable.
        for (uint256 i = 0; i < flowFunc.length; ++i) {
            // Warp to a different time.
            params.timeJump = _passTime(params.timeJump);

            // Create a unique value for stream ID.
            uint256 streamId = uint256(keccak256(abi.encodePacked(initialStreamId, finalStreamId, i)));
            // Bound the stream id to lie within the range of newly created streams.
            streamId = _bound(streamId, initialStreamId, finalStreamId - 1);

            // Execute the flow function mentioned in flowFunc[i].
            _executeFunc(
                flowFunc[i],
                streamId,
                params.ratePerSecond,
                params.depositAmount,
                params.refundAmount,
                params.withdrawAtTime
            );
        }
    }

    /// @dev Execute the Flow function based on the `flowFunc` value.
    /// @param flowFunc Defines which function to call from the Flow contract.
    /// @param streamId The stream id to use.
    /// @param ratePerSecond The rate per second.
    /// @param depositAmount The deposit amount.
    /// @param refundAmount The refund amount.
    /// @param withdrawAtTime The time to withdraw at.
    function _executeFunc(
        FlowFunc flowFunc,
        uint256 streamId,
        uint128 ratePerSecond,
        uint128 depositAmount,
        uint128 refundAmount,
        uint40 withdrawAtTime
    )
        private
    {
        if (flowFunc == FlowFunc.adjustRatePerSecond) {
            _test_AdjustRatePerSecond(streamId, ratePerSecond);
        } else if (flowFunc == FlowFunc.deposit) {
            _test_Deposit(streamId, depositAmount);
        } else if (flowFunc == FlowFunc.pause) {
            _test_Pause(streamId);
        } else if (flowFunc == FlowFunc.refund) {
            _test_Refund(streamId, refundAmount);
        } else if (flowFunc == FlowFunc.restart) {
            _test_Restart(streamId, ratePerSecond);
        } else if (flowFunc == FlowFunc.void) {
            _test_Void(streamId);
        } else if (flowFunc == FlowFunc.withdrawAt) {
            _test_WithdrawAt(streamId, withdrawAtTime);
        }
    }

    /// @notice Simulate passage of time.
    function _passTime(uint256 timeJump) internal returns (uint256) {
        // Hash the time jump with the current timestamp to create a unique value.
        timeJump = uint256(keccak256(abi.encodePacked(getBlockTimestamp(), timeJump)));

        // Bound the time jump.
        timeJump = _bound(timeJump, 0, 10 days);

        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });
        return timeJump;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               ADJUST-RATE-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    function _test_AdjustRatePerSecond(uint256 streamId, uint128 newRatePerSecond) private {
        // Create unique values by hashing the fuzzed params with index.
        newRatePerSecond = boundRatePerSecond(uint128(uint256(keccak256(abi.encodePacked(newRatePerSecond, streamId)))));

        // Make sure the requirements are respected.
        resetPrank({ msgSender: flow.getSender(streamId) });
        if (flow.isPaused(streamId)) {
            flow.restart(streamId, RATE_PER_SECOND);
        }
        if (newRatePerSecond == flow.getRatePerSecond(streamId)) {
            newRatePerSecond += 1;
        }

        uint128 beforeSnapshotAmount = flow.getSnapshotDebt(streamId);
        uint128 totalDebt = flow.totalDebtOf(streamId);
        uint128 ongoingDebt = flow.ongoingDebtOf(streamId);

        // It should emit 1 {AdjustFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit AdjustFlowStream({
            streamId: streamId,
            totalDebt: totalDebt,
            oldRatePerSecond: flow.getRatePerSecond(streamId),
            newRatePerSecond: newRatePerSecond
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        flow.adjustRatePerSecond({ streamId: streamId, newRatePerSecond: newRatePerSecond });

        // It should update snapshot debt.
        uint128 actualSnapshotDebt = flow.getSnapshotDebt(streamId);
        uint128 expectedSnapshotDebt = ongoingDebt + beforeSnapshotAmount;
        assertEq(actualSnapshotDebt, expectedSnapshotDebt, "snapshot debt");

        // It should set the new rate per second
        uint128 actualRatePerSecond = flow.getRatePerSecond(streamId);
        uint128 expectedRatePerSecond = newRatePerSecond;
        assertEq(actualRatePerSecond, expectedRatePerSecond, "rate per second");

        // It should update snapshot time
        uint128 actualSnapshotTime = flow.getSnapshotTime(streamId);
        uint128 expectedSnapshotTime = getBlockTimestamp();
        assertEq(actualSnapshotTime, expectedSnapshotTime, "snapshot time");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    function _test_Create(address recipient, address sender, uint128 ratePerSecond, bool transferable) private {
        uint256 expectedStreamId = flow.nextStreamId();

        vm.expectEmit({ emitter: address(flow) });
        emit Transfer({ from: address(0), to: recipient, tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: expectedStreamId });

        vm.expectEmit({ emitter: address(flow) });
        emit CreateFlowStream({
            streamId: expectedStreamId,
            token: token,
            sender: sender,
            recipient: recipient,
            ratePerSecond: ratePerSecond,
            transferable: transferable
        });

        uint256 actualStreamId = flow.create({
            recipient: recipient,
            sender: sender,
            ratePerSecond: ratePerSecond,
            token: token,
            transferable: transferable
        });

        Flow.Stream memory actualStream = flow.getStream(actualStreamId);
        Flow.Stream memory expectedStream = Flow.Stream({
            balance: 0,
            isPaused: false,
            isStream: true,
            isTransferable: transferable,
            snapshotTime: getBlockTimestamp(),
            ratePerSecond: ratePerSecond,
            snapshotDebt: 0,
            sender: sender,
            token: token,
            tokenDecimals: IERC20Metadata(address(token)).decimals()
        });

        // It should create the stream.
        assertEq(actualStreamId, expectedStreamId, "stream ID");
        assertEq(actualStream, expectedStream);

        // It should bump the next stream id.
        assertEq(flow.nextStreamId(), expectedStreamId + 1, "next stream ID");

        // It should mint the NFT.
        address actualNFTOwner = flow.ownerOf({ tokenId: actualStreamId });
        address expectedNFTOwner = recipient;
        assertEq(actualNFTOwner, expectedNFTOwner, "NFT owner");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    function _test_Deposit(uint256 streamId, uint128 depositAmount) private {
        uint8 tokenDecimals = flow.getTokenDecimals(streamId);

        // Following variables are used during assertions.
        uint256 initialTokenBalance = token.balanceOf(address(flow));
        uint128 initialStreamBalance = flow.getBalance(streamId);

        uint128 depositAmountSeed = uint128(uint256(keccak256(abi.encodePacked(depositAmount, streamId))));
        depositAmount = boundDepositAmount(depositAmountSeed, initialStreamBalance, tokenDecimals);

        address sender = flow.getSender(streamId);
        resetPrank({ msgSender: sender });
        deal({ token: address(token), to: sender, give: depositAmount });
        safeApprove(depositAmount);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: sender, to: address(flow), value: depositAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({ streamId: streamId, funder: sender, amount: depositAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: token, from: sender, to: address(flow), amount: depositAmount });

        // Make the deposit.
        flow.deposit(streamId, depositAmount);

        // Assert that the token balance of stream has been updated.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance + depositAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = initialStreamBalance + depositAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PAUSE
    //////////////////////////////////////////////////////////////////////////*/

    function _test_Pause(uint256 streamId) private {
        // Make sure the requirements are respected.
        resetPrank({ msgSender: flow.getSender(streamId) });
        if (flow.isPaused(streamId)) {
            flow.restart(streamId, RATE_PER_SECOND);
        }

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: streamId,
            sender: flow.getSender(streamId),
            recipient: flow.getRecipient(streamId),
            totalDebt: flow.totalDebtOf(streamId)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Pause the stream.
        flow.pause(streamId);

        // Assert that the stream is paused.
        assertTrue(flow.isPaused(streamId), "paused");

        // Assert that the rate per second is 0.
        assertEq(flow.getRatePerSecond(streamId), 0, "rate per second");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REFUND
    //////////////////////////////////////////////////////////////////////////*/

    function _test_Refund(uint256 streamId, uint128 refundAmount) private {
        // Make sure the requirements are respected.
        address sender = flow.getSender(streamId);
        resetPrank({ msgSender: sender });

        // If the refundable amount less than 1, deposit some funds.
        if (flow.refundableAmountOf(streamId) <= 1) {
            uint128 depositAmount =
                flow.uncoveredDebtOf(streamId) + getDefaultDepositAmount(flow.getTokenDecimals(streamId));
            depositOnStream(streamId, depositAmount);
        }

        // Bound the refund amount to avoid error.
        refundAmount = boundUint128(refundAmount, 1, flow.refundableAmountOf(streamId));

        uint256 initialTokenBalance = token.balanceOf(address(flow));
        uint128 initialStreamBalance = flow.getBalance(streamId);

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: sender, value: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit RefundFromFlowStream({ streamId: streamId, sender: sender, amount: refundAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Request the refund.
        flow.refund(streamId, refundAmount);

        // Assert that the token balance of stream has been updated.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance - refundAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = initialStreamBalance - refundAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      RESTART
    //////////////////////////////////////////////////////////////////////////*/

    function _test_Restart(uint256 streamId, uint128 ratePerSecond) private {
        // Make sure the requirements are respected.
        address sender = flow.getSender(streamId);
        resetPrank({ msgSender: sender });
        if (!flow.isPaused(streamId)) {
            flow.pause(streamId);
        }

        uint256 ratePerSecondSeed = uint256(keccak256(abi.encodePacked(ratePerSecond, streamId)));
        ratePerSecond = boundRatePerSecond(uint128(ratePerSecondSeed));

        // It should emit 1 {RestartFlowStream}, 1 {MetadataUpdate} event.
        vm.expectEmit({ emitter: address(flow) });
        emit RestartFlowStream({ streamId: streamId, sender: sender, ratePerSecond: ratePerSecond });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        flow.restart({ streamId: streamId, ratePerSecond: ratePerSecond });

        // It should restart the stream.
        assertFalse(flow.isPaused(streamId));

        // It should update rate per second.
        uint128 actualRatePerSecond = flow.getRatePerSecond(streamId);
        assertEq(actualRatePerSecond, ratePerSecond, "ratePerSecond");

        // It should update snapshot time.
        uint40 actualSnapshotTime = flow.getSnapshotTime(streamId);
        assertEq(actualSnapshotTime, getBlockTimestamp(), "snapshotTime");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        VOID
    //////////////////////////////////////////////////////////////////////////*/

    function _test_Void(uint256 streamId) private {
        // Make sure the requirements are respected.
        address sender = flow.getSender(streamId);
        address recipient = flow.getRecipient(streamId);
        uint128 uncoveredDebt = flow.uncoveredDebtOf(streamId);

        resetPrank({ msgSender: sender });

        if (uncoveredDebt == 0) {
            if (flow.isPaused(streamId)) {
                flow.restart(streamId, RATE_PER_SECOND);
            }

            // In case of a big depletion time, refund and withdraw all the funds, and then warp for one second. Warping
            // too much in the future would affect the other tests.
            uint128 refundableAmount = flow.refundableAmountOf(streamId);
            if (refundableAmount > 0) {
                // Refund and withdraw all the funds.
                flow.refund(streamId, refundableAmount);
            }
            if (flow.coveredDebtOf(streamId) > 0) {
                flow.withdrawMax(streamId, recipient);
            }

            vm.warp({ newTimestamp: getBlockTimestamp() + 100 seconds });
            uncoveredDebt = flow.uncoveredDebtOf(streamId);
        }

        uint128 beforeVoidBalance = flow.getBalance(streamId);

        // It should emit 1 {VoidFlowStream}, 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit VoidFlowStream({
            streamId: streamId,
            recipient: recipient,
            sender: sender,
            caller: sender,
            newTotalDebt: beforeVoidBalance,
            writtenOffDebt: uncoveredDebt
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        flow.void(streamId);

        // It should set the rate per second to zero.
        assertEq(flow.getRatePerSecond(streamId), 0, "rate per second");

        // It should pause the stream.
        assertTrue(flow.isPaused(streamId), "paused");

        // It should set the total debt to stream balance.
        assertEq(flow.totalDebtOf(streamId), beforeVoidBalance, "total debt");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    WITHDRAW-AT
    //////////////////////////////////////////////////////////////////////////*/

    function _test_WithdrawAt(uint256 streamId, uint40 withdrawTime) private {
        uint256 withdrawTimeSeed = uint256(keccak256(abi.encodePacked(withdrawTime, streamId)));
        withdrawTime = boundUint40(uint40(withdrawTimeSeed), flow.getSnapshotTime(streamId), getBlockTimestamp());

        uint8 tokenDecimals = flow.getTokenDecimals(streamId);

        uint128 streamBalance = flow.getBalance(streamId);
        if (streamBalance == 0) {
            uint128 depositAmount = getDefaultDepositAmount(tokenDecimals);
            depositOnStream(streamId, depositAmount);
            streamBalance = flow.getBalance(streamId);
        }

        uint128 totalDebt = flow.getSnapshotDebt(streamId)
            + getDenormalizedAmount(
                flow.getRatePerSecond(streamId) * (withdrawTime - flow.getSnapshotTime(streamId)),
                flow.getTokenDecimals(streamId)
            );
        uint128 withdrawAmount = streamBalance < totalDebt ? streamBalance : totalDebt;

        (, address caller,) = vm.readCallers();
        address recipient = flow.getRecipient(streamId);

        uint256 tokenBalance = token.balanceOf(address(flow));

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: address(flow), to: recipient, value: withdrawAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit WithdrawFromFlowStream({
            streamId: streamId,
            to: recipient,
            token: token,
            caller: caller,
            withdrawAmount: withdrawAmount,
            withdrawTime: withdrawTime
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Withdraw the tokens.
        flow.withdrawAt(streamId, recipient, withdrawTime);

        // It should update snapshot time.
        assertEq(flow.getSnapshotTime(streamId), withdrawTime, "snapshot time");

        // It should decrease the total debt by withdrawn amount.
        uint128 actualTotalDebt = flow.getSnapshotDebt(streamId)
            + getDenormalizedAmount(
                flow.getRatePerSecond(streamId) * (withdrawTime - flow.getSnapshotTime(streamId)),
                flow.getTokenDecimals(streamId)
            );
        uint128 expectedTotalDebt = totalDebt - withdrawAmount;
        assertEq(actualTotalDebt, expectedTotalDebt, "total debt");

        // It should reduce the stream balance by the withdrawn amount.
        uint128 actualStreamBalance = flow.getBalance(streamId);
        uint128 expectedStreamBalance = streamBalance - withdrawAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // It should reduce the token balance of stream.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = tokenBalance - withdrawAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balance");
    }
}
