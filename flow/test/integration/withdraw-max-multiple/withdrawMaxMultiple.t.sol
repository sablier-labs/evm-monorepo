// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Integration_Test } from "../Integration.t.sol";

contract WithdrawMaxMultiple_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_WithdrawMaxMultiple_ArrayCountZero() external {
        uint256[] memory streamIds = new uint256[](0);
        openEnded.withdrawMaxMultiple(streamIds);
    }

    function test_RevertGiven_OnlyNull() external whenArrayCountsNotZero {
        defaultStreamIds[0] = nullStreamId;
        defaultStreamIds[1] = nullStreamId;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.withdrawMaxMultiple({ streamIds: defaultStreamIds });
    }

    function test_RevertGiven_SomeNull() external whenArrayCountsNotZero {
        defaultStreamIds[0] = nullStreamId;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.withdrawMaxMultiple({ streamIds: defaultStreamIds });
    }

    function test_WithdrawMaxMultiple() external whenArrayCountsNotZero givenNotNull {
        defaultDeposit();
        defaultDeposit(defaultStreamIds[1]);

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[0]);
        uint40 expectedLastTimeUpdate = uint40(block.timestamp - ONE_MONTH);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[1]);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(defaultStreamIds[0], ONE_MONTH_STREAMED_AMOUNT)
        });
        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamIds[0],
            to: users.recipient,
            asset: dai,
            withdrawnAmount: ONE_MONTH_STREAMED_AMOUNT
        });

        vm.expectEmit({ emitter: address(dai) });
        emit IERC20.Transfer({
            from: address(openEnded),
            to: users.recipient,
            value: normalizeTransferAmount(defaultStreamIds[1], ONE_MONTH_STREAMED_AMOUNT)
        });
        vm.expectEmit({ emitter: address(openEnded) });
        emit WithdrawFromOpenEndedStream({
            streamId: defaultStreamIds[1],
            to: users.recipient,
            asset: dai,
            withdrawnAmount: ONE_MONTH_STREAMED_AMOUNT
        });

        openEnded.withdrawMaxMultiple({ streamIds: defaultStreamIds });

        assertEq(openEnded.getRemainingAmount(defaultStreamIds[0]), 0, "remaining amount");
        assertEq(openEnded.getRemainingAmount(defaultStreamIds[1]), 0, "remaining amount");

        uint128 actualStreamBalance = openEnded.getBalance(defaultStreamIds[0]);
        uint128 expectedStreamBalance = DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT;
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        actualStreamBalance = openEnded.getBalance(defaultStreamIds[1]);
        assertEq(actualStreamBalance, expectedStreamBalance, "stream balance");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[0]);
        expectedLastTimeUpdate = WARP_ONE_MONTH;
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");

        actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamIds[1]);
        assertEq(actualLastTimeUpdate, expectedLastTimeUpdate, "last time updated");
    }
}
