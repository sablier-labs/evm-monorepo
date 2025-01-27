// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Shared_Integration_Concrete_Test } from "./../Concrete.t.sol";

contract DepletionTimeOf_Integration_Concrete_Test is Shared_Integration_Concrete_Test {
    function test_RevertGiven_Null() external {
        bytes memory callData = abi.encodeCall(flow.depletionTimeOf, nullStreamId);
        expectRevert_Null(callData);
    }

    function test_RevertGiven_Paused() external givenNotNull {
        bytes memory callData = abi.encodeCall(flow.depletionTimeOf, defaultStreamId);
        expectRevert_Paused(callData);
    }

    function test_RevertGiven_BalanceZero() external givenNotNull givenNotPaused {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierFlow_StreamBalanceZero.selector, defaultStreamId));
        flow.depletionTimeOf(defaultStreamId);
    }

    function test_GivenUncoveredDebt() external givenNotNull givenNotPaused givenBalanceNotZero {
        uint256 depletionTimestamp = WARP_SOLVENCY_PERIOD + 1;
        vm.warp({ newTimestamp: depletionTimestamp });

        // Check that uncovered debt is greater than 0.
        assertGt(flow.uncoveredDebtOf(defaultStreamId), 0);

        // It should return 0.
        uint256 actualDepletionTime = flow.depletionTimeOf(defaultStreamId);
        assertEq(actualDepletionTime, 0, "depletion time");
    }

    modifier givenNoUncoveredDebt() {
        _;
    }

    function test_WhenExactDivision() external givenNotNull givenNotPaused givenBalanceNotZero givenNoUncoveredDebt {
        // Create a stream with a rate per second such that the deposit amount produces no remainder when divided by the
        // rate per second.
        UD21x18 rps = UD21x18.wrap(2e18);
        uint256 streamId = createDefaultStream(rps, usdc);
        depositDefaultAmount(streamId);
        uint256 solvencyPeriod = DEPOSIT_AMOUNT_18D / rps.unwrap();

        // It should return the time at which the total debt exceeds the balance.
        uint40 actualDepletionTime = uint40(flow.depletionTimeOf(streamId));
        uint40 exptectedDepletionTime = ONE_MONTH_SINCE_START + uint40(solvencyPeriod + 1);
        assertEq(actualDepletionTime, exptectedDepletionTime, "depletion time");
    }

    function test_WhenNotExactDivision()
        external
        givenNotNull
        givenNotPaused
        givenBalanceNotZero
        givenNoUncoveredDebt
    {
        // It should return the time at which the total debt exceeds the balance.
        uint40 actualDepletionTime = uint40(flow.depletionTimeOf(defaultStreamId));
        uint256 expectedDepletionTime = WARP_SOLVENCY_PERIOD + 1;
        assertEq(actualDepletionTime, expectedDepletionTime, "depletion time");
    }
}
