// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierV2OpenEnded } from "src/interfaces/ISablierV2OpenEnded.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract RestartStream_Integration_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        openEnded.cancel({ streamId: defaultStreamId });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData = abi.encodeCall(ISablierV2OpenEnded.restartStream, (defaultStreamId, RATE_PER_SECOND));
        expectRevertDueToDelegateCall(callData);
    }

    function test_RevertGiven_Null() external whenNotDelegateCalled {
        expectRevertNull();
        openEnded.restartStream({ streamId: nullStreamId, ratePerSecond: RATE_PER_SECOND });
    }

    function test_RevertGiven_NotCanceled() external whenNotDelegateCalled givenNotNull {
        uint256 streamId = createDefaultStream();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_StreamNotCanceled.selector, streamId));
        openEnded.restartStream({ streamId: streamId, ratePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_CallerUnauthorized_Recipient()
        external
        whenNotDelegateCalled
        givenNotNull
        givenCanceled
        whenCallerUnauthorized
    {
        resetPrank({ msgSender: users.recipient });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        openEnded.restartStream({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        givenNotNull
        givenCanceled
        whenCallerUnauthorized
    {
        resetPrank({ msgSender: users.eve });
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamId, users.eve)
        );
        openEnded.restartStream({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND });
    }

    function test_RevertWhen_ratePerSecondZero()
        external
        whenNotDelegateCalled
        givenNotNull
        givenCanceled
        whenCallerAuthorized
    {
        vm.expectRevert(Errors.SablierV2OpenEnded_RatePerSecondZero.selector);
        openEnded.restartStream({ streamId: defaultStreamId, ratePerSecond: 0 });
    }

    function test_RestartStream()
        external
        whenNotDelegateCalled
        givenNotNull
        givenCanceled
        whenCallerAuthorized
        whenratePerSecondNonZero
    {
        openEnded.restartStream({ streamId: defaultStreamId, ratePerSecond: RATE_PER_SECOND });

        bool isCanceled = openEnded.isCanceled(defaultStreamId);
        assertFalse(isCanceled);

        uint128 actualratePerSecond = openEnded.getRatePerSecond(defaultStreamId);
        assertEq(actualratePerSecond, RATE_PER_SECOND, "ratePerSecond");

        uint40 actualLastTimeUpdate = openEnded.getLastTimeUpdate(defaultStreamId);
        assertEq(actualLastTimeUpdate, block.timestamp, "lastTimeUpdate");
    }
}
