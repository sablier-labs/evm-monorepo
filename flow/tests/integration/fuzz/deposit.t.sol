// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Shared_Integration_Fuzz_Test } from "./Fuzz.t.sol";

contract Deposit_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /// @dev Checklist:
    /// - It should deposit token into a stream. 40% runs should load streams from fixtures.
    /// - It should emit the following events: {Transfer}, {MetadataUpdate}, {DepositFlowStream}
    ///
    /// Given enough runs, all of the following scenarios should be fuzzed:
    /// - Multiple non-zero values for callers.
    /// - Multiple non-zero values for deposit amount.
    /// - Multiple streams to deposit into, each with different token decimals and rps.
    /// - Multiple points in time.
    function testFuzz_Deposit(
        address caller,
        uint256 streamId,
        uint128 depositAmount,
        uint40 timeJump,
        uint8 decimals
    )
        external
        whenNoDelegateCall
        givenNotNull
    {
        vm.assume(caller != address(0) && caller != address(flow));

        (streamId,,) = useFuzzedStreamOrCreate(streamId, decimals);

        // Following variables are used during assertions.
        uint256 initialAggregateAmount = flow.aggregateBalance(token);
        uint256 initialTokenBalance = token.balanceOf(address(flow));
        uint128 initialStreamBalance = flow.getBalance(streamId);

        // Bound the deposit amount to avoid overflow.
        depositAmount = boundDepositAmount(depositAmount, initialStreamBalance, decimals);

        // Bound the time jump to provide a realistic time frame.
        timeJump = boundUint40(timeJump, 0 seconds, 100 weeks);

        // Change prank to caller and deal some tokens to him.
        deal({ token: address(token), to: caller, give: depositAmount });
        resetPrank(caller);

        // Approve the flow contract to spend the token.
        token.approve(address(flow), depositAmount);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: getBlockTimestamp() + timeJump });

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(token) });
        emit IERC20.Transfer({ from: caller, to: address(flow), value: depositAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({ streamId: streamId, funder: caller, amount: depositAmount });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: streamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: token, from: caller, to: address(flow), amount: depositAmount });

        // Make the deposit.
        flow.deposit(streamId, depositAmount, users.sender, users.recipient);

        // Assert that the token balance of stream has been updated.
        uint256 actualTokenBalance = token.balanceOf(address(flow));
        uint256 expectedTokenBalance = initialTokenBalance + depositAmount;
        assertEq(actualTokenBalance, expectedTokenBalance, "token balanceOf");

        // Assert that stored balance in stream has been updated.
        uint256 actualStreamBalance = flow.getBalance(streamId);
        uint256 expectedStreamBalance = initialStreamBalance + depositAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // Assert that aggregate amount has been updated.
        uint256 actualAggregateAmount = flow.aggregateBalance(token);
        uint256 expectedAggregateAmount = initialAggregateAmount + depositAmount;
        assertEq(actualAggregateAmount, expectedAggregateAmount, "aggregate amount");
    }
}
