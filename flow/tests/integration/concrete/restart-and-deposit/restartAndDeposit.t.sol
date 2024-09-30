// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC4906 } from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD21x18 } from "@prb/math/src/UD21x18.sol";

import { ISablierFlow } from "src/interfaces/ISablierFlow.sol";

import { Integration_Test } from "../../Integration.t.sol";

contract RestartAndDeposit_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        // Pause the stream for this test.
        flow.pause({ streamId: defaultStreamId });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D));
        expectRevert_DelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (nullStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D));
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Voided() external whenNoDelegateCall givenNotNull {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D));
        expectRevert_Voided(callData);
    }

    function test_RevertWhen_CallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerNotSender
    {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D));
        expectRevert_CallerRecipient(callData);
    }

    function test_RevertWhen_CallerMaliciousThirdParty()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotVoided
        whenCallerNotSender
    {
        bytes memory callData =
            abi.encodeCall(flow.restartAndDeposit, (defaultStreamId, RATE_PER_SECOND, DEPOSIT_AMOUNT_6D));
        expectRevert_CallerMaliciousThirdParty(callData);
    }

    function test_WhenCallerSender() external whenNoDelegateCall givenNotNull givenNotVoided {
        // It should perform the ERC-20 transfer.
        // It should emit 1 {RestartFlowStream}, 1 {Transfer}, 1 {DepositFlowStream} and 1 {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.RestartFlowStream({
            streamId: defaultStreamId,
            sender: users.sender,
            ratePerSecond: RATE_PER_SECOND
        });

        vm.expectEmit({ emitter: address(usdc) });
        emit IERC20.Transfer({ from: users.sender, to: address(flow), value: DEPOSIT_AMOUNT_6D });

        vm.expectEmit({ emitter: address(flow) });
        emit ISablierFlow.DepositFlowStream({
            streamId: defaultStreamId,
            funder: users.sender,
            amount: DEPOSIT_AMOUNT_6D
        });

        vm.expectEmit({ emitter: address(flow) });
        emit IERC4906.MetadataUpdate({ _tokenId: defaultStreamId });

        // It should perform the ERC-20 transfer.
        expectCallToTransferFrom({ token: usdc, from: users.sender, to: address(flow), amount: DEPOSIT_AMOUNT_6D });

        flow.restartAndDeposit({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND, amount: DEPOSIT_AMOUNT_6D });

        // It should restart the stream.
        bool isPaused = flow.isPaused(defaultStreamId);
        assertFalse(isPaused);

        // It should update the rate per second.
        UD21x18 actualRatePerSecond = flow.getRatePerSecond(defaultStreamId);
        assertEq(actualRatePerSecond, RATE_PER_SECOND, "ratePerSecond");

        // It should update snapshot time.
        uint40 actualSnapshotTime = flow.getSnapshotTime(defaultStreamId);
        assertEq(actualSnapshotTime, getBlockTimestamp(), "snapshotTime");

        // It should update the stream balance.
        uint128 actualStreamBalance = flow.getBalance(defaultStreamId);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT_6D;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");
    }
}
