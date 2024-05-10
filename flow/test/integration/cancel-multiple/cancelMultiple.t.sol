// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../Integration.t.sol";

contract CancelMultiple_Integration_Concrete_Test is Integration_Test {
    function setUp() public override {
        Integration_Test.setUp();

        vm.warp({ newTimestamp: WARP_ONE_MONTH });
    }

    function test_CancelMultiple_ArrayCountZero() external whenNotDelegateCalled {
        uint256[] memory streamIds = new uint256[](0);
        openEnded.cancelMultiple(streamIds);
    }

    function test_RevertGiven_OnlyNull() external whenNotDelegateCalled whenArrayCountNotZero {
        defaultStreamIds[0] = nullStreamId;
        defaultStreamIds[1] = nullStreamId;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.cancelMultiple({ streamIds: defaultStreamIds });
    }

    function test_RevertGiven_SomeNull() external whenNotDelegateCalled whenArrayCountNotZero {
        defaultStreamIds[0] = nullStreamId;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2OpenEnded_Null.selector, nullStreamId));
        openEnded.cancelMultiple({ streamIds: defaultStreamIds });
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        givenNotNull
        whenCallerUnauthorized
    {
        resetPrank({ msgSender: users.eve });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        openEnded.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedAllStreams_Recipient()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        givenNotNull
        whenCallerUnauthorized
    {
        resetPrank({ msgSender: users.recipient });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamIds[0], users.recipient
            )
        );
        openEnded.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        givenNotNull
        whenCallerUnauthorized
    {
        uint256 eveStreamId = openEnded.create({
            sender: users.eve,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai
        });

        resetPrank({ msgSender: users.eve });
        defaultStreamIds[0] = eveStreamId;
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamIds[1], users.eve)
        );
        openEnded.cancelMultiple(defaultStreamIds);
    }

    function test_RevertWhen_CallerUnauthorizedSomeStreams_Recipient()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        givenNotNull
        whenCallerUnauthorized
    {
        defaultStreamIds[0] = openEnded.create({
            sender: users.recipient,
            recipient: users.recipient,
            ratePerSecond: RATE_PER_SECOND,
            asset: dai
        });

        resetPrank({ msgSender: users.recipient });

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2OpenEnded_Unauthorized.selector, defaultStreamIds[1], users.recipient
            )
        );
        openEnded.cancelMultiple(defaultStreamIds);
    }

    function test_CancelMultiple()
        external
        whenNotDelegateCalled
        whenArrayCountNotZero
        givenNotNull
        whenCallerUnauthorized
    {
        openEnded.cancelMultiple(defaultStreamIds);

        assertTrue(openEnded.isCanceled(defaultStreamIds[0]));
        assertTrue(openEnded.isCanceled(defaultStreamIds[1]));

        assertEq(openEnded.getRatePerSecond(defaultStreamIds[0]), 0);
        assertEq(openEnded.getRatePerSecond(defaultStreamIds[1]), 0);
    }
}
