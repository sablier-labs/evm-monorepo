// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract RestartAndDeposit_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        flow.pause({ streamId: defaultStreamId });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierFlow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        flow.restartAndDeposit({ streamId: nullStreamId, ratePerSecond: RATE_PER_SECOND, amount: DEPOSIT_AMOUNT });
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenPaused
        whenCallerIsNotTheSender
    {
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        flow.restartAndDeposit({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND, amount: DEPOSIT_AMOUNT });
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenPaused
        whenCallerIsNotTheSender
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_Unauthorized.selector, defaultStreamId, users.eve));
        flow.restartAndDeposit({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND, amount: DEPOSIT_AMOUNT });
    }

    function test_RestartAndDeposit()
        external
        whenNotDelegateCalled
        givenNotNull
        givenPaused
        whenCallerIsTheSender
        whenRatePerSecondIsNotZero
    {
        vm.expectEmit({ emitter: address(flow) });
        emit RestartFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            asset: dai,
            ratePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: users.sender,
            to: address(flow),
            value: normalizeAmountWithStreamId(defaultStreamId, DEPOSIT_AMOUNT)
        });

        vm.expectEmit({ emitter: address(flow) });
        emit DepositFlowStream({
            streamId: defaultStreamId,
            funder: users.sender,
            asset: dai,
            depositAmount: DEPOSIT_AMOUNT
        });

        vm.expectEmit({ emitter: address(flow) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        flow.restartAndDeposit({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND, amount: DEPOSIT_AMOUNT });

        bool isPaused = flow.isPaused(defaultStreamId);
        assertFalse(isPaused);

        uint128 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, RATE_PER_SECOND, "ratePerSecond");

        uint40 actualLastTimeUpdate = flow.getLastTimeUpdate(defaultStreamId);
        assertEq(actualLastTimeUpdate, block.timestamp, "lastTimeUpdate");

        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
