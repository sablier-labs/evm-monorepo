// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract DepositAndPause_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Advance the time past the solvency period so that there is debt.
        vm.warp({ newTimestamp: block.timestamp + SOLVENCY_PERIOD + 1 days });
    }

    function test_RevertWhen_DelegateCalled() external {
        bytes memory callData = abi.encodeCall(ISablierFlow.depositAndPause, (defaultStreamId, DEPOSIT_AMOUNT));
        // it should revert
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        // it should revert
        expectRevertNull();
        flow.depositAndPause(nullStreamId, DEPOSIT_AMOUNT);
    }

    function test_RevertGiven_Paused() external whenNotDelegateCalled givenNotNull {
        // it should revert
        expectRevertPaused();
        flow.depositAndPause(defaultStreamId, DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_CallerIsRecipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotSender
    {
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        // it should revert
        flow.depositAndPause(defaultStreamId, DEPOSIT_AMOUNT);
    }

    function test_RevertWhen_CallerIsMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenNotPaused
        whenCallerIsNotSender
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.eve));
        // it should revert
        flow.depositAndPause(defaultStreamId, DEPOSIT_AMOUNT);
    }

    function test_WhenCallerIsSender() external whenNotDelegateCalled givenNotNull givenNotPaused {
        uint128 depositAmount = flow.streamDebtOf(defaultStreamId);
        uint128 previousStreamBalance = flow.getBalance(defaultStreamId);
        uint128 previousRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        uint128 previousStreamedAmount = flow.streamedAmountOf(defaultStreamId);

        // it should emit 1 {Transfer}, 1 {DepositFlowStream}, 1 {PauseFlowStream}, 1 {MetadataUpdate} events
        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: users.sender,
            to: address(flow),
            value: normalizeAmountWithStreamId(defaultStreamId, depositAmount)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({
            streamId: defaultStreamId,
            funder: users.sender,
            asset: dai,
            depositAmount: depositAmount
        });

        vm.expectEmit({ emitter: address(flow) });
        emit PauseFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            recipient: users.recipient,
            amountOwedToRecipient: previousRemainingAmount + previousStreamedAmount,
            asset: dai
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // it should perform the ERC20 transfer
        expectCallToTransferFrom({
            asset: dai,
            from: users.sender,
            to: address(flow),
            amount: normalizeAmountWithStreamId(defaultStreamId, depositAmount)
        });

        flow.depositAndPause(defaultStreamId, depositAmount);

        // it should update the stream balance
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = previousStreamBalance + depositAmount;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        // it should pause the stream
        assertTrue(flow.isPaused(defaultStreamId), "is paused");

        // it should set rate per second to 0
        uint256 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, 0, "rate per second");

        // it should update the remaining amount
        uint128 actualRemainingAmount = flow.getRemainingAmount(defaultStreamId);
        assertEq(actualRemainingAmount, previousRemainingAmount + previousStreamedAmount, "remaining amount");
    }
}
